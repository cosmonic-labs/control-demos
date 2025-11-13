# Cosmonic Control + Linkerd Service Mesh Demo

This demo shows how to integrate Cosmonic Control with Linkerd service mesh to gain observability, security, and reliability features for WebAssembly workloads.

## Prerequisites

- Kind cluster with Cosmonic Control installed
- Linkerd CLI installed
- kubectl configured
- Helm installed

## Installation

### 1. Install Linkerd CLI

```bash
# macOS
brew install linkerd

# Linux
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh
export PATH=$PATH:$HOME/.linkerd2/bin

# Verify installation
linkerd version
```

### 2. Install Linkerd Control Plane

```bash
# Check pre-flight
linkerd check --pre

# Install Linkerd CRDs
linkerd install --crds | kubectl apply -f -

# Install Linkerd control plane
linkerd install | kubectl apply -f -

# Wait for Linkerd to be ready
linkerd check

# This should show all checks passing
```

### 3. Install Linkerd Viz (Dashboard & Metrics)

```bash
# Install Linkerd Viz extension
linkerd viz install | kubectl apply -f -

# Wait for viz to be ready
linkerd viz check

# Access the dashboard
linkerd viz dashboard &
```

The dashboard will open in your browser at http://localhost:50750

## Meshing Cosmonic Control

### Option 1: Mesh the Entire cosmonic-system Namespace

This is the simplest approach - all pods in the namespace get meshed automatically:

```bash
# Add annotation to namespace
kubectl annotate namespace cosmonic-system linkerd.io/inject=enabled

# Restart deployments to inject proxies
kubectl rollout restart deployment -n cosmonic-system

# Verify injection
linkerd viz stat deployment -n cosmonic-system
```

### Option 2: Mesh Specific Deployments

For more granular control, mesh individual deployments:

```bash
# Mesh only the Envoy ingress
kubectl patch deployment/envoy -n cosmonic-system -p '{"spec": {"template":{"metadata":{"annotations":{"linkerd.io/inject":"enabled"}}}} }'
```

```bash
# Mesh only the wasmCloud host
kubectl patch deployment/hostgroup -n cosmonic-system -p '{"spec": {"template":{"metadata":{"annotations":{"linkerd.io/inject":"enabled"}}}} }'
```

## Verification & Observability

### 1. Check Mesh Status

```bash
# View all meshed deployments
linkerd viz stat deployments -A

# View specific namespace
linkerd viz stat deployments -n cosmonic-system

# Expected output shows:
# - SUCCESS RATE: Should be close to 100%
# - RPS: Requests per second
# - P50/P95/P99 LATENCY: Response time percentiles
```

### 2. View Live Traffic

```bash
# Watch live requests to Envoy
linkerd viz tap deployment/envoy -n cosmonic-system
```

### 3. Top Command (like kubectl top for traffic)

```bash
# Show top deployments by request rate
linkerd viz top deployment -n cosmonic-system

# Show routes with most traffic
linkerd viz routes deployment/envoy -n cosmonic-system
```

### 4. Access Grafana Dashboard

```bash
# Open the Linkerd dashboard
linkerd viz dashboard &

# Navigate to:
# - Grafana → Dashboards → Linkerd
# - View metrics for deployment, namespace, or route
```

## Troubleshooting

### Proxy Not Injected

```bash
# Check if namespace is annotated
kubectl get namespace cosmonic-system -o yaml | grep linkerd

# Check if deployment has annotation
kubectl get deployment envoy -n cosmonic-system -o yaml | grep linkerd

# Verify pod has linkerd-proxy container
kubectl get pod -n cosmonic-system -l app=envoy -o json | \
  jq -r '.items[0].spec.containers[].name'
```

### No Metrics Showing

```bash
# Check Linkerd viz is running
linkerd viz check

# Verify prometheus is scraping
kubectl port-forward -n linkerd-viz svc/prometheus 9090:9090

# Check if metrics are present
curl http://localhost:9090/api/v1/label/__name__/values | grep request_total
```

### Certificate Issues

```bash
# Check certificate expiry
linkerd check --proxy

# Rotate certificates if needed
linkerd upgrade | kubectl apply -f -
```

## Clean Up

```bash
# Remove Linkerd annotation
kubectl annotate namespace cosmonic-system linkerd.io/inject-

# Restart pods to remove proxies
kubectl rollout restart deployment -n cosmonic-system
kubectl rollout restart deployment -n blobby
kubectl rollout restart deployment -n blobby-ui

# Uninstall Linkerd Viz
linkerd viz uninstall | kubectl delete -f -

# Uninstall Linkerd control plane
linkerd uninstall | kubectl delete -f -

# Remove CRDs (careful - this is permanent)
linkerd uninstall --crds | kubectl delete -f -
```

## Key Takeaways

1. **Seamless Integration**: Linkerd meshes Cosmonic Control without code changes
2. **Observability**: Real-time metrics for WasmCloud components
3. **Reliability**: Built-in retries, timeouts, and circuit breaking

## Additional Resources

- [Linkerd Documentation](https://linkerd.io/docs/)
- [Cosmonic Control Documentation](https://cosmonic.com/docs/)
- [Service Mesh Patterns](https://linkerd.io/2/features/)
- [Production Best Practices](https://linkerd.io/2/tasks/production/)
