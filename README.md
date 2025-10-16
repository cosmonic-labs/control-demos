# Cosmonic Control Demos

This repository contains demos and examples for [Cosmonic Control](https://cosmonic.com/), an enterprise control plane for managing WebAssembly (Wasm) workloads in cloud native environments.

Cosmonic Control is built on [wasmCloud](https://wasmcloud.com/), an Incubating project at the [Cloud Native Computing Foundation (CNCF)](https://www.cncf.io/).

## Install Cosmonic Control

In order to try these demos and examples, you will need a **Kubernetes cluster** and an **installation of Cosmonic Control**.

### Install local Kubernetes environment

For the best local Kubernetes development experience, we recommend installing `kind` with the following `kind-config.yaml` configuration:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
# One control plane node and three "workers."
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30950
    hostPort: 80
    protocol: TCP
```

This will help enable simple local ingress with Envoy.

Start the cluster:

```shell
kind create cluster --config=kind-config.yaml
```

### Install Cosmonic Control

:::warning[License key required]
You'll need a **trial license key** to follow these instructions. Sign up for Cosmonic Control's [free trial](/trial) to get a key.
:::

Deploy Cosmonic Control to Kubernetes with Helm:

```shell
helm install cosmonic-control oci://ghcr.io/cosmonic/cosmonic-control\
  --version 0.3.0\
  --namespace cosmonic-system\
  --create-namespace\
  --set envoy.service.type=NodePort\
  --set envoy.service.httpNodePort=30950\
  --set cosmonicLicenseKey="<insert license here>"
```

Deploy a HostGroup:

```shell
helm install hostgroup oci://ghcr.io/cosmonic/cosmonic-control-hostgroup --version 0.3.0 --namespace cosmonic-system
```

## Contents

This repository includes...

### Components

- `blobby`: A blob storage ("blobby") fileserver backed by NATS, implemented as a Wasm component
- `blobstore-nats`: A demonstration of blob storage operations that exposes the results via HTTP, implemented as a Wasm component
- `hello-world`: "Hello world" Wasm component, built with Rust
- `hono-swagger-ui`: Wasm component for documenting and testing RESTful APIs, built with TypeScript, Hono, and Swagger UI
- `http-server`: Wasm component for an HTTP server with multiple endpoints, built with Go
- `petstore-mcp`: An example of a TypeScript-based MCP server for the Swagger PetStore API, implemented as a Wasm component 
- `welcome-tour`: Wasm component introducing users to the core features of Cosmonic Control, built with TypeScript and Hono

### Demos

- `http-ingress-nginx`: Demo for NGINX as an Ingress Controller for Wasm workloads
- `integrations/argo-cd`: Demo for using GitOps patterns with Argo CD, Cosmonic Control, and Wasm components

### Miscellaneous

- `trial`: YAML documents used to configure trial deployments of Cosmonic Control

## Makefile

This repository includes a Makefile enabling simplified usage of Helm commands from a local download of this repository using `make`:

* `make render-<demo name>`: Render chart templates locally and display the output for a given demo (Ex. `make render-blobby`).
* `make helm-install-<demo name>`: Deploy a given demo in a dedicated namespace with an HTTPTrigger. (Ex. `make helm-install-blobby`).
* `make helm-delete-<demo name>`: Delete a given demo installed with `make helm-install`. (Ex. `make helm-delete-blobby`)

## Further Reading

For more information on Cosmonic Control, visit [cosmonic.com](https://cosmonic.com/) and the [Cosmonic Control documentation](https://cosmonic.com/docs/).

For more on building components, see the [Developer Guide](https://cosmonic.com/docs/developer-guide/developing-webassembly-components) in the Cosmonic Control documentation. 