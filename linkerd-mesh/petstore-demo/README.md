# Petstore MCP Server Demo with Linkerd & MetalLB

This demo showcases deploying a Petstore MCP (Model Context Protocol) server on Kubernetes with Cosmonic Control, using Linkerd service mesh for observability and mTLS, and MetalLB for LoadBalancer functionality in Kind clusters.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Linkerd Service Mesh                         │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                                                           │  │
│  │                 ┌────────────────────┐                    │  │
│  │                 │  Petstore MCP      │                    │  │
│  │                 │  Server (Wasm)     │                    │  │
│  │                 │                    │                    │  │
│  │                 │ [linkerd-proxy]    │                    │  │
│  │                 └────────────────────┘                    │  │
│  │                          ▲                                │  │
│  │                          │                                │  │
│  │                          │                                │  │
│  │                 ┌────────┴──────────┐                     │  │
│  │                 │   Ingress (HTTP)  │                     │  │
│  │                 │  petstore-mcp...  │                     │  │
│  │                 └───────────────────┘                     │  │
│  │                                                           │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│         All traffic encrypted with mTLS and observable         │
└─────────────────────────────────────────────────────────────────┘
```

## Components

1. **Petstore MCP Server** (WebAssembly component)
   - MCP server implementing the Model Context Protocol
   - Deployed via Cosmonic Control HTTPTrigger
   - Provides tools for interacting with Petstore API
   - Accessible via ingress endpoint

2. **Linkerd Service Mesh**
   - Buoyant Enterprise Linkerd
   - Automatic mTLS between all services
   - L7 metrics and observability
   - Uses opaque ports for non-HTTP protocols (NATS)

3. **MetalLB LoadBalancer**
   - Provides LoadBalancer IPs in Kind clusters
   - Automatically configured from Kind network CIDR
   - L2 advertisement mode

## Prerequisites

- Kubernetes cluster (Kind recommended)
- `kubectl` CLI tool
- `helm` CLI tool
- `linkerd` CLI tool
- `docker` (for Kind network detection)
- `jq` (for JSON parsing)
- Cosmonic Control installed
- Buoyant Linkerd license

### Kind Cluster Setup

Create a Kind cluster with the recommended configuration:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30950
    hostPort: 80
    protocol: TCP
```

```bash
curl -fLO https://raw.githubusercontent.com/cosmonic-labs/control-demos/refs/heads/main/kind-config.yaml
kind create cluster --config=kind-config.yaml
rm kind-config.yaml
```

### Install Cosmonic Control

You need a trial license key from [cosmonic.com/trial](https://cosmonic.com/trial).

```bash
helm install cosmonic-control oci://ghcr.io/cosmonic/cosmonic-control \
  --version 0.3.0 \
  --namespace cosmonic-system \
  --create-namespace \
  --set envoy.service.type=NodePort \
  --set envoy.service.httpNodePort=30950 \
  --set cosmonicLicenseKey="<your-license-key>"

# Deploy a HostGroup
helm install hostgroup oci://ghcr.io/cosmonic/cosmonic-control-hostgroup \
  --version 0.3.0 \
  --namespace cosmonic-system
```

### Install Buoyant Enterprise Linkerd

```bash
# Set your Buoyant license
export BUOYANT_LICENSE="eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJCdW95YW50IEluYyIsInN1YiI6ImxpY2Vuc2UiLCJhdWQiOiJjb3Ntb25pYyIsImV4cCI6NDEwMjQ0NDgwMCwiQ2xpZW50SUQiOiJXc0lTNTlDaWhzRlZzaFpUIiwiQ2xpZW50U2VjcmV0IjoiOWZiMzI4ODFhZGZkNjIwNmQ2MzY0OTYxNGZkN2U3MmMyMDkxZWZkZDIwNWRlNWQ1YmQwMDhkZTFmY2M4Y2MyNyIsIlByb2R1Y3QiOiJCRUwiLCJWZXJzaW9uIjoyLCJNYW5hZ2VkQ29udHJvbFBsYW5lRW5hYmxlZCI6dHJ1ZSwiTWFuYWdlZERhdGFQbGFuZUVuYWJsZWQiOnRydWUsIkVudGVycHJpc2VFbmFibGVkIjp0cnVlLCJIQVpMRW5hYmxlZCI6ZmFsc2UsIkZJUFNFbmFibGVkIjpmYWxzZSwiUGF0Y2hSZWxlYXNlc0VuYWJsZWQiOmZhbHNlfQ.65AO8ZaWVEeTyG2-3dwTIR7wu7pGJUBua6vITlI9NQORb0hfnGG2xLeORDLfW6YIud5RkErMh9y6BEz0GW3m6Q"

# Install Buoyant CLI and Linkerd
curl https://enterprise.buoyant.io/install | sh
export PATH=$PATH:$HOME/.linkerd2/bin

# Install Linkerd CRDs
linkerd install --crds | kubectl apply -f -

# Install Linkerd control plane
linkerd install \
  --set identity.issuer.scheme=kubernetes.io/tls \
  | kubectl apply -f -

# Verify installation
linkerd check

# Install Linkerd Viz (dashboard & metrics)
linkerd viz install | kubectl apply -f -
linkerd viz check
```

## Quick Start

Use the automated deployment script:

```bash
cd linkerd-mesh/petstore-demo
chmod +x deploy.sh
./deploy.sh
```

The script will:
1. Check prerequisites
2. Verify Linkerd installation
3. Install MetalLB (if not already installed)
4. Deploy and validate echo service
5. Deploy Petstore MCP server
6. Verify mesh injection
7. Display access points and next steps

## Manual Installation

### Step 1: Install MetalLB

```bash
chmod +x install-metallb.sh
./install-metallb.sh
```

This script will:
- Detect your Kind network CIDR automatically
- Install MetalLB via Helm
- Create an IP address pool
- Configure L2 advertisement

### Step 2: Validate MetalLB with Echo Service

```bash
kubectl apply -f echo-service.yaml

# Wait for LoadBalancer IP
kubectl get svc echo -n echo -w

# Test the service
ECHO_IP=$(kubectl get svc echo -n echo -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl http://$ECHO_IP
# Should output: "hello there"
```

### Step 3: Deploy Petstore MCP Server

The MCP server is deployed using the HTTP trigger Helm chart:

```bash
helm install petstore-mcp ../../charts/http-trigger \
  -f ../../petstore-mcp/values.http-trigger.yaml \
  -n petstore

# Check the HTTPTrigger status
kubectl get httptrigger -n petstore

# View the workload status
kubectl get workload,workloaddeployment -n petstore

# The MCP server runs as a WebAssembly component on the wasmCloud host
kubectl get pods -n cosmonic-system
```

**Note:** The Helm chart deployment is the only supported method for deploying the MCP server. Direct YAML deployment is not supported as it requires Config CRDs that aren't part of the standard Cosmonic Control installation.

### Step 4: Verify Linkerd Mesh

```bash
# Check mesh status
linkerd viz stat deployment -n petstore
linkerd viz stat deployment -n echo

# View mTLS connections
linkerd viz edges deployment -n petstore

# Watch live traffic
linkerd viz tap deployment -n petstore

# Open dashboard
linkerd viz dashboard
```

## Configuration Details

### Petstore MCP Server Configuration

The Petstore MCP server is deployed using the HTTP trigger Helm chart with the following configuration:

```yaml
# petstore-mcp/values.http-trigger.yaml
components:
  - name: petstore-mcp
    image: ghcr.io/cosmonic-labs/petstore-mcp-server:v0.2.0

ingress:
  host: "petstore-mcp.localhost.cosmonic.sh"

pathNote: "/v1/mcp"
```

**Note:** The MCP server is configured to connect to a Petstore API backend. The backend API service should be deployed separately and accessible at `http://petstore.petstore.svc.cluster.local:8080`. When both services are in the Linkerd mesh, connections are automatically encrypted with mTLS.

### Opaque Ports vs Skip Ports

This demo uses **opaque ports** instead of skip-outbound-ports for non-HTTP protocols (recommended by Linkerd team):

**Previous approach (deprecated):**
```yaml
config.linkerd.io/skip-outbound-ports: "4222,6222,7422,8222"
```

**Current approach (recommended):**
```yaml
config.linkerd.io/opaque-ports: "4222,6222,7422,8222"
```

Benefits of opaque ports:
- Traffic still flows through Linkerd proxy (maintains mesh security)
- Bypasses HTTP protocol detection (better performance for TCP)
- Provides basic TCP metrics while avoiding L7 parsing overhead
- Maintains mTLS encryption

The opaque ports configuration is applied to the Cosmonic hostgroup deployment in `../kustomize/linkerd-inject-patch.yaml`.

### MetalLB IP Pool

The MetalLB installation script automatically detects your Kind network and configures an IP pool:

```bash
# Example: If Kind network is 172.18.0.0/16
# MetalLB will use: 172.18.255.200 - 172.18.255.250

docker inspect kind | jq .[].IPAM.Config
```

## Testing the MCP Server

The Petstore MCP server implements the Model Context Protocol using **StreamableHTTP transport**. You can test it using the provided script or manually with curl.

### Automated Testing

Run the comprehensive MCP test script:

```bash
./test-mcp.sh
```

This script will:
1. Initialize an MCP session
2. List all available tools
3. Call the `get_pet_find_by_status` tool with `status=available`
4. Verify backend API connectivity
5. Check Linkerd mesh metrics

### Manual MCP Protocol Testing

The MCP protocol uses StreamableHTTP transport with the following workflow:

**Step 1: Initialize the session**
```bash
curl -X POST \
  -H "Host: petstore-mcp.localhost.cosmonic.sh" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Accept: text/event-stream" \
  http://localhost/v1/mcp \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {
      "protocolVersion": "2024-11-05",
      "capabilities": {},
      "clientInfo": {
        "name": "test-client",
        "version": "1.0.0"
      }
    }
  }'
```

**Step 2: List available tools**
```bash
curl -X POST \
  -H "Host: petstore-mcp.localhost.cosmonic.sh" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Accept: text/event-stream" \
  http://localhost/v1/mcp \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/list"
  }'
```

**Step 3: Call the findPetsByStatus tool**
```bash
curl -X POST \
  -H "Host: petstore-mcp.localhost.cosmonic.sh" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Accept: text/event-stream" \
  http://localhost/v1/mcp \
  -d '{
    "jsonrpc": "2.0",
    "id": 3,
    "method": "tools/call",
    "params": {
      "name": "get_pet_find_by_status",
      "arguments": {
        "status": "available"
      }
    }
  }'
```

**Note:** The MCP server requires both `application/json` and `text/event-stream` in the Accept headers. Responses use StreamableHTTP format with `event: message` and `data:` prefixes.

### Using MCP Inspector

Install and run the MCP Inspector:

```bash
npx @modelcontextprotocol/inspector
```

Configure the connection:
- **Transport Type**: Streamable HTTP
- **URL**: `http://petstore-mcp.localhost.cosmonic.sh/v1/mcp`
- **Connection Type**: Via Proxy

### Using curl

```bash
# List available tools
curl http://petstore-mcp.localhost.cosmonic.sh/v1/mcp/tools

# Test the MCP endpoint
curl http://petstore-mcp.localhost.cosmonic.sh/v1/mcp
```

### Port-forward for Local Access

If you don't have ingress configured:

```bash
# Port-forward to MCP server
kubectl port-forward -n petstore svc/petstore-mcp 8080:8080

# Access locally
curl http://localhost:8080/v1/mcp
```

## Observability

### Linkerd Dashboard

```bash
linkerd viz dashboard
```

Navigate to:
- **Namespaces** → `petstore` to see all services
- **Deployments** → View success rates, latencies, RPS
- **Tap** → Watch live requests in real-time
- **Top** → See top talkers by traffic volume

### Metrics to Monitor

```bash
# Deployment statistics
linkerd viz stat deployment -n petstore

# Success rates by route
linkerd viz routes deployment/petstore -n petstore

# Service-to-service connections
linkerd viz edges deployment -n petstore

# Live request inspection
linkerd viz tap deployment/petstore -n petstore
```

### Key Metrics

| Metric | Good | Warning | Critical |
|--------|------|---------|----------|
| Success Rate | >99.9% | >99% | <99% |
| P50 Latency | <10ms | <50ms | >100ms |
| P99 Latency | <100ms | <500ms | >1s |
| Meshed % | 100% | >90% | <90% |

## Troubleshooting

### MetalLB Not Assigning IPs

```bash
# Check MetalLB pods
kubectl get pods -n metallb-system

# Check IP address pool
kubectl get ipaddresspool -n metallb-system

# Check L2 advertisement
kubectl get l2advertisement -n metallb-system

# View MetalLB logs
kubectl logs -n metallb-system -l app.kubernetes.io/name=metallb
```

### Linkerd Proxy Not Injected

```bash
# Check namespace annotation
kubectl get namespace petstore -o yaml | grep linkerd

# Verify pod has proxy
kubectl get pod -n petstore -o yaml | grep -A 5 "linkerd-proxy"

# Check injection status
kubectl describe pod <pod-name> -n petstore
```

### MCP Server Not Responding

```bash
# Check HTTPTrigger status
kubectl get httptrigger petstore-mcp -n petstore -o yaml

# View MCP server logs
kubectl logs -n petstore -l control.cosmonic.io/httptrigger=petstore-mcp

# Check Petstore API connectivity
kubectl exec -n petstore deployment/petstore -- curl http://petstore:8080/api/v3/pet/findByStatus?status=available
```

### Config Not Applied

```bash
# Verify Config resource exists
kubectl get config petstore-mcp-config -n petstore -o yaml

# Check HTTPTrigger references the config
kubectl get httptrigger petstore-mcp -n petstore -o yaml | grep -A 5 config
```

## Clean Up

### Remove Petstore Demo

```bash
# Uninstall MCP server via Helm
helm uninstall petstore-mcp -n petstore

# Remove Kubernetes resources
kubectl delete -f echo-service.yaml

# Delete namespaces
kubectl delete namespace petstore echo
```

### Remove MetalLB

```bash
helm uninstall metallb -n metallb-system
kubectl delete namespace metallb-system
```

### Remove Linkerd

```bash
# Remove Viz
linkerd viz uninstall | kubectl delete -f -

# Remove control plane
linkerd uninstall | kubectl delete -f -

# Remove CRDs (careful - permanent)
linkerd uninstall --crds | kubectl delete -f -
```

## Architecture Decisions

### Why Opaque Ports?

Linkerd team recommends using opaque ports over skip-outbound-ports because:
1. Traffic still goes through the proxy (security maintained)
2. Basic TCP metrics available
3. mTLS still applied
4. No L7 parsing overhead for non-HTTP protocols

### Why MetalLB?

Kind clusters don't have a built-in LoadBalancer implementation. MetalLB:
1. Provides LoadBalancer IPs from your Kind network
2. Works in L2 mode without BGP setup
3. Essential for testing LoadBalancer services locally

### Why Buoyant Enterprise Linkerd?

Buoyant Enterprise Linkerd provides:
1. Enterprise support
2. FIPS compliance options
3. High availability features
4. Longer certificate validity
5. Managed control/data plane options

## Additional Resources

- [Linkerd Documentation](https://linkerd.io/docs/)
- [Buoyant Enterprise Linkerd](https://buoyant.io/enterprise-linkerd)
- [MetalLB Documentation](https://metallb.universe.tf/)
- [Cosmonic Control Documentation](https://cosmonic.com/docs/)
- [MCP Protocol Specification](https://modelcontextprotocol.io/)
- [Petstore MCP Source](https://github.com/cosmonic-labs/mcp-server-template-ts)

## Next Steps

1. Implement authorization policies with Linkerd
2. Add traffic splitting for canary deployments
3. Configure retries and timeouts
4. Set up Prometheus/Grafana for metrics
5. Deploy multiple MCP servers for high availability
6. Add circuit breaking patterns
7. Implement rate limiting

## License

This demo is part of the Cosmonic Labs control-demos repository.
