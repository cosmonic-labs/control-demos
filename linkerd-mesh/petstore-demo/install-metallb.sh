#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to print section headers
print_section() {
    echo -e "\n${BLUE}▶ $1${NC}"
}

# Function to print success messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print warnings
print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Function to print errors
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Banner
echo -e "${PURPLE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   MetalLB LoadBalancer Installation                           ║
║   for Kind Kubernetes Cluster                                 ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Check prerequisites
print_section "Checking prerequisites..."

if ! command -v kubectl &> /dev/null; then
    print_error "kubectl not found"
    exit 1
fi

if ! command -v helm &> /dev/null; then
    print_error "helm not found"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    print_error "docker not found"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    print_error "jq not found - required for IP address detection"
    echo "Please install jq: brew install jq (macOS) or apt-get install jq (Linux)"
    exit 1
fi

print_success "All prerequisites found"

# Detect Kind network CIDR
print_section "Detecting Kind network configuration..."

NETWORK_INFO=$(docker inspect kind 2>/dev/null | jq -r '.[].IPAM.Config')

if [ -z "$NETWORK_INFO" ] || [ "$NETWORK_INFO" = "null" ]; then
    print_error "Could not detect Kind network - is Kind running?"
    exit 1
fi

# Extract the subnet (we'll use the first network block)
SUBNET=$(echo "$NETWORK_INFO" | jq -r '.[0].Subnet')

if [ -z "$SUBNET" ] || [ "$SUBNET" = "null" ]; then
    print_error "Could not extract subnet from Kind network"
    exit 1
fi

print_success "Detected Kind network: $SUBNET"

# Calculate IP range for MetalLB (last 50 IPs in the subnet)
# For example, if subnet is 192.168.97.0/24, we'll use 192.168.97.200-192.168.97.250
BASE_IP=$(echo "$SUBNET" | cut -d'/' -f1 | awk -F'.' '{print $1"."$2"."$3}')
IP_START="${BASE_IP}.200"
IP_END="${BASE_IP}.250"

echo -e "${YELLOW}MetalLB IP Pool: ${IP_START} - ${IP_END}${NC}"

# Add MetalLB Helm repo
print_section "Adding MetalLB Helm repository..."

if helm repo list | grep -q "^metallb"; then
    print_warning "MetalLB repo already exists, updating..."
    helm repo update metallb
else
    helm repo add metallb https://metallb.github.io/metallb
    print_success "MetalLB repo added"
fi

# Install MetalLB
print_section "Installing MetalLB..."

if helm list -n metallb-system | grep -q "^metallb"; then
    print_warning "MetalLB already installed"
    read -p "Do you want to upgrade it? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        helm upgrade metallb metallb/metallb \
            --namespace metallb-system \
            --create-namespace \
            --wait
        print_success "MetalLB upgraded"
    fi
else
    helm install metallb metallb/metallb \
        --namespace metallb-system \
        --create-namespace \
        --wait
    print_success "MetalLB installed"
fi

# Wait for MetalLB to be ready
print_section "Waiting for MetalLB to be ready..."
kubectl wait --namespace metallb-system \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/name=metallb \
    --timeout=90s

print_success "MetalLB is ready"

# Create IP address pool
print_section "Creating MetalLB IP address pool..."

cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: demo-pool
  namespace: metallb-system
spec:
  addresses:
  - ${IP_START}-${IP_END}
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: demo-pool-advertisement
  namespace: metallb-system
spec:
  ipAddressPools:
  - demo-pool
EOF

print_success "IP address pool created: ${IP_START}-${IP_END}"

# Success banner
echo ""
echo -e "${GREEN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   ✓ MetalLB Installation Complete!                           ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo ""
echo "MetalLB is now ready to assign LoadBalancer IPs to services"
echo ""
echo "IP Pool Range: ${IP_START} - ${IP_END}"
echo ""
echo "Next steps:"
echo "  • Deploy the echo service to validate MetalLB"
echo "  • Deploy petstore services with LoadBalancer type"
echo ""
