#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Banner
echo -e "${PURPLE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   Petstore MCP Server Demo                                    ║
║   with Linkerd Service Mesh & MetalLB                         ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

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

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

if ! command -v linkerd &> /dev/null; then
    print_error "Linkerd CLI not found"
    echo ""
    echo "Please install Linkerd CLI:"
    echo "  macOS:   brew install linkerd"
    echo "  Linux:   curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh"
    exit 1
fi

print_success "All prerequisites found"

# Check if Linkerd is installed
print_section "Checking Linkerd installation..."

if ! kubectl get namespace linkerd &> /dev/null; then
    print_error "Linkerd is not installed"
    echo ""
    echo "Please install Linkerd first using the Buoyant enterprise edition:"
    echo ""
    echo "export BUOYANT_LICENSE=\"your-license-key\""
    echo "curl https://enterprise.buoyant.io/install | sh"
    echo ""
    exit 1
fi

if ! linkerd check &> /dev/null; then
    print_error "Linkerd is not healthy"
    linkerd check
    exit 1
fi

print_success "Linkerd is installed and healthy"

# Check if MetalLB is installed
print_section "Checking MetalLB installation..."

if ! kubectl get namespace metallb-system &> /dev/null; then
    print_warning "MetalLB is not installed"
    echo ""
    read -p "Would you like to install MetalLB now? [Y/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        bash "$SCRIPT_DIR/install-metallb.sh"
    else
        print_error "MetalLB is required for this demo"
        exit 1
    fi
else
    print_success "MetalLB is installed"
fi

# Deploy echo service for validation
print_section "Deploying echo service for MetalLB validation..."

if kubectl get namespace echo &> /dev/null; then
    print_warning "Echo service already exists"
else
    kubectl apply -f "$SCRIPT_DIR/echo-service.yaml"
    print_success "Echo service deployed"

    # Wait for LoadBalancer IP
    echo "Waiting for LoadBalancer IP..."
    kubectl wait --for=condition=ready pod -l app=echo -n echo --timeout=90s

    sleep 5

    ECHO_IP=$(kubectl get svc echo -n echo -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    if [ -n "$ECHO_IP" ]; then
        print_success "Echo service is available at: http://${ECHO_IP}"
        echo "Testing echo service..."
        if curl -s "http://${ECHO_IP}" | grep -q "hello there"; then
            print_success "Echo service test passed!"
        else
            print_warning "Echo service test failed or still initializing"
        fi
    else
        print_warning "LoadBalancer IP not yet assigned"
    fi
fi

# Deploy petstore MCP server
print_section "Deploying Petstore MCP server..."

# Navigate to repo root to access charts
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Deploy using Helm with http-trigger chart
helm install petstore-mcp "$REPO_ROOT/charts/http-trigger" \
    -f "$REPO_ROOT/petstore-mcp/values.http-trigger.yaml" \
    -n petstore \
    --wait \
    --timeout 120s

if [ $? -eq 0 ]; then
    print_success "Petstore MCP server deployed"
else
    print_error "Failed to deploy Petstore MCP server"
    echo "Attempting to check existing deployment..."
    if helm list -n petstore | grep -q "petstore-mcp"; then
        print_warning "Petstore MCP already installed"
    else
        exit 1
    fi
fi

# Wait for HTTPTrigger to be ready
echo "Waiting for HTTPTrigger workload to be ready..."
sleep 10

# Verify HTTPTrigger exists
if kubectl get httptrigger petstore-mcp -n petstore &> /dev/null; then
    print_success "HTTPTrigger created successfully"
else
    print_warning "HTTPTrigger not found - checking status"
fi

# Verify Linkerd mesh injection
print_section "Verifying Linkerd mesh injection..."

echo ""
echo "Petstore namespace mesh status:"
linkerd viz stat deployment -n petstore 2>/dev/null || echo "No deployments meshed yet - this is normal for HTTPTrigger workloads"

echo ""
echo "Echo namespace mesh status:"
linkerd viz stat deployment -n echo 2>/dev/null || echo "Checking mesh status..."

# Get LoadBalancer IPs
print_section "Getting service endpoints..."

echo "MCP Server endpoint: http://petstore-mcp.localhost.cosmonic.sh/v1/mcp"

# Success banner
echo ""
echo -e "${GREEN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   ✓ Deployment Complete!                                      ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo ""
echo "🎉 Petstore MCP Server Demo is now running!"
echo ""
echo "📊 Access Points:"
echo ""
echo "  • Petstore MCP Server:      http://petstore-mcp.localhost.cosmonic.sh/v1/mcp"
echo "  • Echo Service:             http://${ECHO_IP} (MetalLB validation)"
echo ""
echo "🔍 Monitoring & Debugging:"
echo ""
echo "  • View Linkerd dashboard:   linkerd viz dashboard"
echo "  • Check mesh status:        linkerd viz stat deployment -n petstore"
echo "  • Watch live traffic:       linkerd viz tap deployment -n petstore"
echo "  • View mTLS connections:    linkerd viz edges deployment -n petstore"
echo ""
echo "🧪 Testing the MCP Server:"
echo ""
echo "  • Install MCP Inspector:    npx @modelcontextprotocol/inspector"
echo "  • Transport Type:           Streamable HTTP"
echo "  • URL:                      http://petstore-mcp.localhost.cosmonic.sh/v1/mcp"
echo "  • Connection Type:          Via Proxy"
echo ""
echo "📖 Documentation: $SCRIPT_DIR/README.md"
echo ""

# Offer to open dashboard
read -p "Would you like to open the Linkerd dashboard now? [Y/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo "Opening dashboard at http://localhost:50750..."
    linkerd viz dashboard &
    sleep 2
    echo ""
    echo "Dashboard is running in the background"
    echo "Press Ctrl-C to stop it when done"
fi
