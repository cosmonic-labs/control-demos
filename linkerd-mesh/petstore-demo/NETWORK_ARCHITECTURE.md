# Petstore MCP Server - Network Architecture

## Network Topology Overview

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                             Host Network (macOS/Linux)                              │
│                                                                                     │
│  External Access Points:                                                            │
│  • http://localhost (NodePort: 30950) ───────────────────┐                          │
│  • http://192.168.97.200 (MetalLB) ──────────────────┐   │                          │
│  • http://192.168.97.201 (MetalLB) ────────────────┐ │   │                          │
│                                                    │ │   │                          │
└────────────────────────────────────────────────────┼─┼───┼──────────────────────────┘
                                                     │ │   │
                    ┌────────────────────────────────┼─┼───┼──────────────────────────┐
                    │                                │ │   │                          │
                    │           Kind Docker Network (192.168.97.0/24)                 │
                    │                                │ │   │                          │
                    │  ┌─────────────────────────────┼─┼───┼────────────────────────┐ │
                    │  │         kind-control-plane  │ │   │                        │ │
                    │  │                             │ │   │                        │ │
                    │  │  Port Mappings:             │ │   │                        │ │
                    │  │  • 80:30950 ────────────────┼─┼───┘                        │ │
                    │  │                             │ │                            │ │
┌───────────────────┼──┼─────────────────────────────┼─┼────────────────────────────┼─┼─┐
│                   │  │   MetalLB IP Pool           │ │                            │ │ │
│  IP Range:        │  │   192.168.97.200-250        │ │                            │ │ │
│  192.168.97.200-  │  │                             │ │                            │ │ │
│  192.168.97.250   │  │   Assigned IPs:             │ │                            │ │ │
│                   │  │   • 192.168.97.200 → echo ──┘ │                            │ │ │
│                   │  │   • 192.168.97.201 → petstore─┘                            │ │ │
└───────────────────┼──┼────────────────────────────────────────────────────────────┼─┼─┘
                    │  │                                                            │ │
                    │  │  ┌─────────────────────────────────────────────────────┐   │ │
                    │  │  │          Linkerd Control Plane (linkerd ns)         │   │ │
                    │  │  │                                                     │   │ │
                    │  │  │  • linkerd-identity:8080                            │   │ │
                    │  │  │  • linkerd-destination:8086                         │   │ │
                    │  │  │  • linkerd-proxy-injector:8443                      │   │ │
                    │  │  │                                                     │   │ │
                    │  │  │  Manages: mTLS certificates, service discovery      │   │ │
                    │  │  └─────────────────────────────────────────────────────┘   │ │
                    │  │                                                            │ │
                    │  │  ┌─────────────────────────────────────────────────────┐   │ │
                    │  │  │      Cosmonic System Namespace (cosmonic-system)    │   │ │
                    │  │  │                                                     │   │ │
                    │  │  │  ┌───────────────────────────────────────────────┐  │   │ │
                    │  │  │  │ Ingress Service (NodePort)                    │  │   │ │
                    │  │  │  │ • Port 80 → 30950 (exposed to host) ─────────────────┘ │
                    │  │  │  │ • Port 7654 → 31728 (gRPC)                    │  │   │ │
                    │  │  │  │ ClusterIP: 10.96.147.119                      │  │   │ │
                    │  │  │  └───────────────────────────────────────────────┘  │   │ │
                    │  │  │           │                                         │   │ │
                    │  │  │           ▼                                         │   │ │
                    │  │  │  ┌─────────────────────────────────────────────┐    │   │ │
                    │  │  │  │ Envoy Pod (Headless Service)                │    │   │ │
                    │  │  │  │                                             │    │   │ │
                    │  │  │  │ ┌────────────────────────────────────────┐  │    │   │ │
                    │  │  │  │ │ envoy container                        │  │    │   │ │
                    │  │  │  │ │ • :8001 (HTTP ingress)                 │  │    │   │ │
                    │  │  │  │ │ • Routes to wasmCloud hosts            │  │    │   │ │
                    │  │  │  │ └────────────────────────────────────────┘  │    │   │ │
                    │  │  │  │ ┌────────────────────────────────────────┐  │    │   │ │
                    │  │  │  │ │ linkerd-proxy (sidecar)                │  │    │   │ │
                    │  │  │  │ │ • :4140 (inbound proxy)                │  │    │   │ │
                    │  │  │  │ │ • :4191 (metrics)                      │  │    │   │ │
                    │  │  │  │ │ • Handles mTLS                         │  │    │   │ │
                    │  │  │  │ └────────────────────────────────────────┘  │    │   │ │
                    │  │  │  └─────────────────────────────────────────────┘    │   │ │
                    │  │  │           │                                         │   │ │
                    │  │  │           │ HTTP (meshed)                           │   │ │
                    │  │  │           ▼                                         │   │ │
                    │  │  │  ┌──────────────────────────────────────────────┐   │   │ │
                    │  │  │  │ HostGroup Pod (wasmCloud host)               │   │   │ │
                    │  │  │  │                                              │   │   │ │
                    │  │  │  │ ┌────────────────────────────────────────┐   │   │   │ │
                    │  │  │  │ │ wasmcloud-host container               │   │   │   │ │
                    │  │  │  │ │ • Runs WebAssembly components          │   │   │   │ │
                    │  │  │  │ │ • Hosts HTTPTrigger workloads          │   │   │   │ │
                    │  │  │  │ └────────────────────────────────────────┘   │   │   │ │
                    │  │  │  │ ┌────────────────────────────────────────┐   │   │   │ │
                    │  │  │  │ │ linkerd-proxy (sidecar)                │   │   │   │ │
                    │  │  │  │ │ • Opaque ports: 4222,6222,7422,8222    │   │   │   │ │
                    │  │  │  │ │   (NATS - bypasses HTTP parsing)       │   │   │   │ │
                    │  │  │  │ │ • All other traffic: HTTP/gRPC proxied │   │   │   │ │
                    │  │  │  │ └────────────────────────────────────────┘   │   │   │ │
                    │  │  │  └──────────────────────────────────────────────┘   │   │ │
                    │  │  │           │                                         │   │ │
                    │  │  │           │ NATS (opaque - TCP passthrough)         │   │ │
                    │  │  │           ▼                                         │   │ │
                    │  │  │  ┌──────────────────────────────────────────────┐   │   │ │
                    │  │  │  │ NATS StatefulSet                             │   │   │ │
                    │  │  │  │ • 4222 (client)  [OPAQUE PORT]               │   │   │ │
                    │  │  │  │ • 6222 (cluster) [OPAQUE PORT]               │   │   │ │
                    │  │  │  │ • 7422 (leafnode)[OPAQUE PORT]               │   │   │ │
                    │  │  │  │ • 8222 (monitor) [OPAQUE PORT]               │   │   │ │
                    │  │  │  └──────────────────────────────────────────────┘   │   │ │
                    │  │  └─────────────────────────────────────────────────────┘   │ │
                    │  │                                                            │ │
                    │  │  ┌─────────────────────────────────────────────────────┐   │ │
                    │  │  │          Echo Namespace (echo)                      │   │ │
                    │  │  │                                                     │   │ │
                    │  │  │  ┌──────────────────────────────────────────────┐   │   │ │
                    │  │  │  │ Echo Service (LoadBalancer)                  │   │   │ │
                    │  │  │  │ • ClusterIP: 10.96.149.219                   │   │   │ │
                    │  │  │  │ • External-IP: 192.168.97.200 (MetalLB) ─────────────┐ │
                    │  │  │  │ • Port: 80 → 8080                            │   │   │ │
                    │  │  │  └──────────────────────────────────────────────┘   │   │ │
                    │  │  │           │                                         │   │ │
                    │  │  │           ▼                                         │   │ │
                    │  │  │  ┌──────────────────────────────────────────────┐   │   │ │
                    │  │  │  │ Echo Pod                                     │   │   │ │
                    │  │  │  │                                              │   │   │ │
                    │  │  │  │ ┌────────────────────────────────────────┐   │   │   │ │
                    │  │  │  │ │ http-echo container                    │   │   │   │ │
                    │  │  │  │ │ • :8080                                │   │   │   │ │
                    │  │  │  │ │ • Returns "hello there"                │   │   │   │ │
                    │  │  │  │ └────────────────────────────────────────┘   │   │   │ │
                    │  │  │  │ ┌────────────────────────────────────────┐   │   │   │ │
                    │  │  │  │ │ linkerd-proxy (sidecar)                │   │   │   │ │
                    │  │  │  │ │ • :4140 (inbound proxy)                │   │   │   │ │
                    │  │  │  │ │ • mTLS enabled                         │   │   │   │ │
                    │  │  │  │ └────────────────────────────────────────┘   │   │   │ │
                    │  │  │  └──────────────────────────────────────────────┘   │   │ │ 
                    │  │  └─────────────────────────────────────────────────────┘   │ │ 
                    │  │                                                            │ │
                    │  │  ┌─────────────────────────────────────────────────────┐   │ │
                    │  │  │       Petstore Namespace (petstore)                 │   │ │
                    │  │  │                                                     │   │ │
                    │  │  │  ┌──────────────────────────────────────────────┐   │   │ │
                    │  │  │  │ Petstore Service (ClusterIP)                 │   │   │ │
                    │  │  │  │ • ClusterIP: 10.96.113.183                   │   │   │ │
                    │  │  │  │ • Port: 8080                                 │   │   │ │
                    │  │  │  │ • Internal only                              │   │   │ │
                    │  │  │  └──────────────────────────────────────────────┘   │   │ │
                    │  │  │           │              ▲                          │   │ │
                    │  │  │           │              │ HTTP (mTLS)              │   │ │
                    │  │  │           │              │                          │   │ │
                    │  │  │  ┌──────────────────────────────────────────────┐   │   │ │
                    │  │  │  │ Petstore-External Service (LoadBalancer)     │   │   │ │
                    │  │  │  │ • ClusterIP: 10.96.178.240                   │   │   │ │ 
                    │  │  │  │ • External-IP: 192.168.97.201 (MetalLB) ─────────────┘ │
                    │  │  │  │ • Port: 80 → 8080                            │   │   │ │
                    │  │  │  └──────────────────────────────────────────────┘   │   │ │
                    │  │  │           │                                         │   │ │
                    │  │  │           ▼                                         │   │ │
                    │  │  │  ┌───────────────────────────────────────────────┐  │   │ │
                    │  │  │  │ Petstore API Pod                              │  │   │ │
                    │  │  │  │                                               │  │   │ │
                    │  │  │  │ ┌─────────────────────────────────────────┐   │  │   │ │
                    │  │  │  │ │ swaggerapi/petstore3 container          │   │  │   │ │
                    │  │  │  │ │ • :8080                                 │   │  │   │ │
                    │  │  │  │ │ • OpenAPI v3 pet store                  │   │  │   │ │
                    │  │  │  │ └─────────────────────────────────────────┘   │  │   │ │
                    │  │  │  │ ┌─────────────────────────────────────────┐   │  │   │ │
                    │  │  │  │ │ linkerd-proxy (sidecar)                 │   │  │   │ │
                    │  │  │  │ │ • :4140 (inbound proxy)                 │   │  │   │ │
                    │  │  │  │ │ • mTLS certificate from linkerd-identity│   │  │   │ │
                    │  │  │  │ └─────────────────────────────────────────┘   │  │   │ │
                    │  │  │  └───────────────────────────────────────────────┘  │   │ │
                    │  │  │           ▲                                         │   │ │
                    │  │  │           │ HTTP (mTLS encrypted)                   │   │ │
                    │  │  │           │                                         │   │ │
                    │  │  │  ┌──────────────────────────────────────────────┐   │   │ │
                    │  │  │  │ Petstore MCP Server (HTTPTrigger Workload)   │   │   │ │
                    │  │  │  │                                              │   │   │ │
                    │  │  │  │ Runs on: wasmCloud host (cosmonic-system)    │   │   │ │
                    │  │  │  │                                              │   │   │ │
                    │  │  │  │ • WebAssembly component                      │   │   │ │
                    │  │  │  │ • MCP protocol endpoint: /v1/mcp             │   │   │ │
                    │  │  │  │ • Connects to: petstore.petstore.svc:8080    │   │   │ │
                    │  │  │  │ • Ingress: petstore-mcp.localhost.cosmonic   │   │   │ │
                    │  │  │  │   .sh                                        │   │   │ │
                    │  │  │  └──────────────────────────────────────────────┘   │   │ │
                    │  │  └─────────────────────────────────────────────────────┘   │ │
                    │  │                                                            │ │
                    │  │  ┌─────────────────────────────────────────────────────┐   │ │
                    │  │  │    Linkerd Viz Namespace (linkerd-viz)              │   │ │
                    │  │  │                                                     │   │ │
                    │  │  │  • Prometheus (metrics collection)                  │   │ │
                    │  │  │  • Grafana (visualization)                          │   │ │
                    │  │  │  • Tap (live traffic inspection)                    │   │ │
                    │  │  │  • Web (dashboard)                                  │   │ │
                    │  │  │                                                     │   │ │
                    │  │  │  Scrapes metrics from all linkerd-proxy sidecars    │   │ │
                    │  │  └─────────────────────────────────────────────────────┘   │ │
                    │  │                                                            │ │
                    │  │  ┌─────────────────────────────────────────────────────┐   │ │
                    │  │  │    MetalLB System Namespace (metallb-system)        │   │ │
                    │  │  │                                                     │   │ │
                    │  │  │  • metallb-controller (IP allocation)               │   │ │
                    │  │  │  • metallb-speaker (L2 advertisement)               │   │ │
                    │  │  │                                                     │   │ │
                    │  │  │  IPAddressPool: 192.168.97.200-250                  │   │ │
                    │  │  │  L2Advertisement: demo-pool                         │   │ │
                    │  │  └─────────────────────────────────────────────────────┘   │ │
                    │  └────────────────────────────────────────────────────────────┘ │
                    └─────────────────────────────────────────────────────────────────┘
```

## Network Flow Diagrams

### 1. External Client → Echo Service (MetalLB LoadBalancer)

```
┌────────────┐
│   Client   │
│  (curl)    │
└─────┬──────┘
      │ HTTP GET http://192.168.97.200
      │
      ▼
┌─────────────────────────────────────────┐
│     Kind Docker Network Bridge          │
│     192.168.97.0/24                     │
└─────┬───────────────────────────────────┘
      │
      │ MetalLB L2 ARP Resolution
      │ (192.168.97.200 → kind-control-plane)
      │
      ▼
┌─────────────────────────────────────────┐
│   MetalLB Speaker (DaemonSet)           │
│   • Announces IP via ARP                │
│   • Routes to echo Service              │
└─────┬───────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────┐
│   Echo Service (LoadBalancer)           │
│   External-IP: 192.168.97.200           │
│   ClusterIP: 10.96.149.219:80           │
└─────┬───────────────────────────────────┘
      │
      │ kube-proxy iptables rules
      │ DNAT: 10.96.149.219:80 → Pod IP:8080
      │
      ▼
┌─────────────────────────────────────────┐
│   Echo Pod                              │
│   ┌─────────────────────────────────┐   │
│   │ linkerd-proxy (init container)  │   │
│   │ • Configures iptables           │   │
│   │ • Redirects traffic to :4140    │   │
│   └─────────────────────────────────┘   │
│   ┌─────────────────────────────────┐   │
│   │ linkerd-proxy (sidecar)         │   │
│   │ :4140 (inbound)                 │   │
│   │ • Terminates mTLS               │   │
│   │ • Collects metrics              │   │
│   │ • Forwards to :8080             │   │
│   └─────┬───────────────────────────┘   │
│         │                               │
│         ▼                               │
│   ┌─────────────────────────────────┐   │
│   │ http-echo container             │   │
│   │ :8080                           │   │
│   │ • Returns "hello there"         │   │
│   └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

### 2. External Client → MCP Server (via Ingress NodePort)

```
┌────────────┐
│   Client   │
│  (curl)    │
└─────┬──────┘
      │ HTTP POST http://localhost/v1/mcp
      │ Host: petstore-mcp.localhost.cosmonic.sh
      │
      ▼
┌─────────────────────────────────────────┐
│   Host Network → Kind Port Mapping      │
│   localhost:80 → 30950                  │
└─────┬───────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────┐
│   Ingress Service (NodePort)            │
│   cosmonic-system namespace             │
│   ClusterIP: 10.96.147.119:80           │
│   NodePort: 30950                       │
└─────┬───────────────────────────────────┘
      │
      │ kube-proxy routes to Envoy pod
      │
      ▼
┌─────────────────────────────────────────┐
│   Envoy Pod (Headless Service)          │
│   ┌─────────────────────────────────┐   │
│   │ linkerd-proxy (sidecar)         │   │
│   │ :4140 (inbound)                 │   │
│   │ • mTLS termination              │   │
│   └─────┬───────────────────────────┘   │
│         │                               │
│         ▼                               │
│   ┌─────────────────────────────────┐   │
│   │ envoy container                 │   │
│   │ :8001                           │   │
│   │ • Reads Host header             │   │
│   │ • Routes to HTTPTrigger         │   │
│   └─────┬───────────────────────────┘   │
└─────────┼───────────────────────────────┘
          │
          │ HTTP to wasmCloud host
          │
          ▼
┌─────────────────────────────────────────┐
│   HostGroup Pod (wasmCloud host)        │
│   ┌─────────────────────────────────┐   │
│   │ linkerd-proxy (sidecar)         │   │
│   │ • Initiates mTLS to Envoy       │   │
│   │ • Opaque ports for NATS         │   │
│   └─────┬───────────────────────────┘   │
│         │                               │
│         ▼                               │
│   ┌─────────────────────────────────┐   │
│   │ wasmcloud-host                  │   │
│   │ • Executes Wasm component       │   │
│   │ • petstore-mcp HTTPTrigger      │   │
│   └─────┬───────────────────────────┘   │
└─────────┼───────────────────────────────┘
          │
          │ HTTP to Petstore API
          │ http://petstore.petstore.svc:8080
          │
          ▼
┌─────────────────────────────────────────┐
│   Petstore Service (ClusterIP)          │
│   ClusterIP: 10.96.113.183:8080         │
│   petstore namespace                    │
└─────┬───────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────┐
│   Petstore Pod                          │
│   ┌─────────────────────────────────┐   │
│   │ linkerd-proxy (sidecar)         │   │
│   │ :4140 (inbound)                 │   │
│   │ • mTLS with wasmCloud host      │   │
│   │ • Validates client certificate  │   │
│   └─────┬───────────────────────────┘   │
│         │                               │
│         ▼                               │
│   ┌─────────────────────────────────┐   │
│   │ swaggerapi/petstore3            │   │
│   │ :8080                           │   │
│   │ • Returns pet data              │   │
│   └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

### 3. wasmCloud Host ↔ NATS (Opaque Ports)

```
┌─────────────────────────────────────────┐
│   HostGroup Pod                         │
│   ┌─────────────────────────────────┐   │
│   │ wasmcloud-host                  │   │
│   │ • Needs NATS for control plane  │   │
│   └─────┬───────────────────────────┘   │
│         │                               │
│         │ TCP to nats.cosmonic-system   │
│         │ :4222 (client port)           │
│         │                               │
│         ▼                               │
│   ┌─────────────────────────────────┐   │
│   │ linkerd-proxy (sidecar)         │   │
│   │                                 │   │
│   │ Opaque Ports: 4222,6222,        │   │
│   │               7422,8222         │   │
│   │                                 │   │
│   │ • NO HTTP protocol detection    │   │
│   │ • TCP passthrough mode          │   │
│   │ • Still applies mTLS            │   │
│   │ • Basic TCP metrics only        │   │
│   └─────┬───────────────────────────┘   │
└─────────┼───────────────────────────────┘
          │
          │ Encrypted TCP (mTLS)
          │ No L7 parsing overhead
          │
          ▼
┌─────────────────────────────────────────┐
│   NATS StatefulSet                      │
│   ┌─────────────────────────────────┐   │
│   │ linkerd-proxy (sidecar)         │   │
│   │ :4140 (inbound)                 │   │
│   │ • Receives encrypted TCP        │   │
│   │ • No HTTP parsing               │   │
│   └─────┬───────────────────────────┘   │
│         │                               │
│         ▼                               │
│   ┌─────────────────────────────────┐   │
│   │ nats-server                     │   │
│   │ :4222 (client)                  │   │
│   │ :6222 (cluster)                 │   │
│   │ :7422 (leafnode)                │   │
│   │ :8222 (monitor)                 │   │
│   └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

## IP Address Allocation

### Kind Network (192.168.97.0/24)

| IP Range               | Purpose              | Notes                      |
| ---------------------- | -------------------- | -------------------------- |
| 192.168.97.0/24        | Kind cluster network | Managed by Docker          |
| 192.168.97.1           | Gateway              | Docker bridge gateway      |
| 192.168.97.2-199       | Reserved             | Pod IPs, Node IPs          |
| **192.168.97.200-250** | **MetalLB Pool**     | **LoadBalancer IPs**       |
| 192.168.97.200         | echo LoadBalancer    | Assigned by MetalLB        |
| 192.168.97.201-250     | Available            | For additional LB services |

### Kubernetes ClusterIP Range (10.96.0.0/12)

| Service  | ClusterIP     | Port     | Type         |
| -------- | ------------- | -------- | ------------ |
| ingress  | 10.96.147.119 | 80, 7654 | NodePort     |
| echo     | 10.96.149.219 | 80       | LoadBalancer |
| petstore | 10.96.113.183 | 8080     | ClusterIP    |

### Pod Network (Calico/Default CNI)

Pods receive IPs from the cluster's pod CIDR (typically 10.244.0.0/16 or similar).

## Port Mapping Summary

### External Access

| External          | Protocol | Internal         | Service | Purpose             |
| ----------------- | -------- | ---------------- | ------- | ------------------- |
| localhost:80      | HTTP     | 30950 (NodePort) | ingress | MCP endpoint access |
| 192.168.97.200:80 | HTTP     | echo:8080        | echo    | MetalLB validation  |

### Linkerd Proxy Ports

| Port | Purpose        | Direction                |
| ---- | -------------- | ------------------------ |
| 4140 | Inbound proxy  | Traffic to application   |
| 4143 | Outbound proxy | Traffic from application |
| 4191 | Admin/metrics  | Prometheus scraping      |

### Opaque Ports (NATS)

| Port | Service       | Protocol | Linkerd Mode     |
| ---- | ------------- | -------- | ---------------- |
| 4222 | NATS client   | TCP      | Opaque (no HTTP) |
| 6222 | NATS cluster  | TCP      | Opaque (no HTTP) |
| 7422 | NATS leafnode | TCP      | Opaque (no HTTP) |
| 8222 | NATS monitor  | TCP      | Opaque (no HTTP) |

**Opaque Port Benefits:**

- Traffic still proxied (mTLS maintained)
- No HTTP/2 upgrade attempts
- No protocol detection overhead
- Better performance for persistent connections
- Basic TCP metrics available

## mTLS Certificate Flow

```
┌──────────────────────────────────────────────────────────────┐
│            Linkerd Identity Service                          │
│            (linkerd-identity pod)                            │
│                                                              │
│  • Root CA certificate                                       │
│  • Issues leaf certificates to proxies                       │
│  • Certificate validity: 24 hours (default)                  │
│  • Auto-rotation before expiry                               │
└──────────────────┬───────────────────────────────────────────┘
                   │
                   │ gRPC (secured)
                   │
        ┌──────────┴──────────┐
        │                     │
        ▼                     ▼
┌───────────────┐     ┌───────────────┐
│ linkerd-proxy │     │ linkerd-proxy │
│ (wasmCloud)   │────▶│ (Petstore)    │
│               │     │               │
│ Client cert:  │mTLS │ Server cert:  │
│ default.      │     │ petstore.     │
│ cosmonic-     │     │ petstore.svc. │
│ system.svc... │     │ cluster.local │
└───────────────┘     └───────────────┘
```

**mTLS Flow:**

1. Each linkerd-proxy requests certificate from linkerd-identity
2. Identity validates ServiceAccount via Kubernetes TokenReview
3. Identity issues certificate with identity from ServiceAccount
4. Proxies use certificates for mutual TLS authentication
5. Certificates rotated automatically before expiry

## Network Policies (Implicit via Linkerd)

Linkerd provides implicit authorization through mTLS identity:

1. **Service-to-Service Authentication**
   - Only services with valid Linkerd certificates can communicate
   - Identity derived from Kubernetes ServiceAccount
   - Automatic rejection of non-meshed traffic (with deny-by-default policy)

2. **Observable Network Paths**
   - All connections tracked by linkerd-proxy
   - Metrics exported to Prometheus
   - Real-time visibility via `linkerd viz tap`

3. **Future: Authorization Policies**

   ```yaml
   apiVersion: policy.linkerd.io/v1alpha1
   kind: AuthorizationPolicy
   metadata:
     name: petstore-api-access
     namespace: petstore
   spec:
     targetRef:
       kind: Server
       name: petstore
     requiredAuthenticationRefs:
       - kind: ServiceAccount
         name: default
         namespace: cosmonic-system
   ```

## Observability & Monitoring

### Metrics Collection Flow

```
┌─────────────────┐
│ linkerd-proxy   │
│ (any pod)       │
│ :4191/metrics   │
└────────┬────────┘
         │
         │ HTTP GET (Prometheus scrape)
         │ Every 15s
         │
         ▼
┌──────────────────────────────────────┐
│  Prometheus (linkerd-viz namespace)  │
│  • Stores metrics (15 day retention) │
│  • PromQL queries                    │
└────────┬─────────────────────────────┘
         │
         │ Grafana dashboards
         │ linkerd viz queries
         │
         ▼
┌──────────────────────────────────────┐
│  Linkerd Dashboard (Web UI)          │
│  localhost:50750                     │
│  • Real-time metrics                 │
│  • Tap (live traffic)                │
│  • Topology view                     │
└──────────────────────────────────────┘
```

### Key Metrics

| Metric                 | Source             | Purpose                      |
| ---------------------- | ------------------ | ---------------------------- |
| `request_total`        | linkerd-proxy:4191 | Request count by destination |
| `response_total`       | linkerd-proxy:4191 | Response count by status     |
| `response_latency_ms`  | linkerd-proxy:4191 | Response time percentiles    |
| `tcp_open_connections` | linkerd-proxy:4191 | Active TCP connections       |
| `tcp_open_total`       | linkerd-proxy:4191 | Total TCP connections opened |

## DNS Resolution

### Service DNS

| FQDN                                  | Resolves To   | Namespace |
| ------------------------------------- | ------------- | --------- |
| `petstore`                            | 10.96.113.183 | petstore  |
| `petstore.petstore`                   | 10.96.113.183 | Any       |
| `petstore.petstore.svc`               | 10.96.113.183 | Any       |
| `petstore.petstore.svc.cluster.local` | 10.96.113.183 | Any       |

### Linkerd Service Mesh DNS

When a workload in `cosmonic-system` calls `petstore.petstore.svc:8080`:

1. DNS query to CoreDNS
2. Returns ClusterIP: 10.96.113.183
3. Outbound proxy (wasmCloud linkerd-proxy) intercepts
4. Proxy queries linkerd-destination for endpoints
5. linkerd-destination returns Pod IPs with routing info
6. Proxy establishes mTLS connection directly to Pod
7. Bypasses kube-proxy/iptables (unless fallback needed)

## Performance Characteristics

### Network Latency (Measured)

| Path                | P50  | P95   | P99   | Notes                |
| ------------------- | ---- | ----- | ----- | -------------------- |
| External → Echo     | 1ms  | 1ms   | 1ms   | MetalLB + Linkerd    |
| External → Petstore | 2ms  | 9ms   | 10ms  | MetalLB + Linkerd    |
| MCP → Petstore API  | ~3ms | ~15ms | ~20ms | mTLS overhead ~1-2ms |

### Linkerd Overhead

- **Memory per proxy**: ~20-30 MB baseline
- **CPU per proxy**: <0.1 core at low traffic
- **Latency overhead**: ~1-2ms for mTLS (P99)
- **Connection establishment**: <5ms (certificate validation)

## Security Boundaries

```
┌─────────────────────────────────────────────────────────────────┐
│  External Network (Untrusted)                                   │
│  • No encryption                                                │
│  • No authentication                                            │
└───────┬─────────────────────────────────────────────────────────┘
        │
        │ LoadBalancer / NodePort
        │ (Unencrypted HTTP)
        │
        ▼
┌─────────────────────────────────────────────────────────────────┐
│  Cluster Ingress (Trust Boundary)                               │
│  • MetalLB (L2 ARP)                                             │
│  • NodePort (kind port mapping)                                 │
└───────┬─────────────────────────────────────────────────────────┘
        │
        │ First linkerd-proxy
        │
        ▼
┌─────────────────────────────────────────────────────────────────┐
│  Linkerd Service Mesh (Trusted)                                 │
│                                                                 │
│  • All pod-to-pod traffic: mTLS                                 │
│  • Identity from ServiceAccount                                 │
│  • Certificate validation                                       │
│  • Authorization policies (future)                              │
│                                                                 │
│  ┌───────────────┐  mTLS   ┌───────────────┐                    │
│  │ Envoy Pod     │────────▶│ wasmCloud Pod │                    │
│  └───────────────┘         └───────────────┘                    │
│         │                          │                            │
│         │ mTLS                     │ mTLS                       │
│         ▼                          ▼                            │
│  ┌───────────────┐         ┌───────────────┐                    │
│  │ NATS Pod      │         │ Petstore Pod  │                    │
│  └───────────────┘         └───────────────┘                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Troubleshooting Network Issues

### Debug Commands

```bash
# Check MetalLB IP assignment
kubectl get svc -A | grep LoadBalancer

# Verify Linkerd proxy injection
kubectl get pod <pod> -o jsonpath='{.spec.containers[*].name}'
# Should include: linkerd-proxy

# Check mTLS status
linkerd viz edges deployment -n <namespace>
# Look for "SECURED" column

# View live traffic
linkerd viz tap deployment/<name> -n <namespace>

# Check iptables rules (if needed)
kubectl exec <pod> -c linkerd-proxy -- iptables-save

# DNS resolution test
kubectl run -it --rm debug --image=nicolaka/netshoot --restart=Never -- \
  nslookup petstore.petstore.svc.cluster.local

# Network connectivity test
kubectl run -it --rm debug --image=nicolaka/netshoot --restart=Never -- \
  curl http://petstore.petstore.svc.cluster.local:8080/api/v3/pet/findByStatus?status=available
```

### Common Issues

1. **LoadBalancer IP pending**
   - Check MetalLB speaker pods
   - Verify IPAddressPool range
   - Ensure L2Advertisement exists

2. **mTLS not working**
   - Check linkerd-proxy injected
   - Verify linkerd-identity running
   - Check certificate validity: `linkerd identity`

3. **High latency**
   - Check if opaque ports configured for non-HTTP
   - Verify connection pooling
   - Monitor proxy CPU/memory

4. **Connection refused**
   - Verify service exists: `kubectl get svc`
   - Check pod ready: `kubectl get pod`
   - Test ClusterIP directly from another pod
