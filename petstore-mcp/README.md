# Petstore MCP Server for Cosmonic Control

This Wasm component is an example of an MCP server compiled to a secure-by-default Wasm sandbox, enabling MCP hosts to utilize the [Swagger PetStore API](https://petstore3.swagger.io/api/v3/openapi.json). The example is written in TypeScript and packaged for deployment to Kubernetes clusters with [Cosmonic Control](https://cosmonic.com/docs/). 

While this component was written for Cosmonic Control, you can run it with any WebAssembly runtime that supports the Component Model and the [WebAssembly System Interface (WASI)](https://wasi.dev/) HTTP API. The component is available as an OCI artifact at `ghcr.io/cosmonic-labs/petstore-mcp-server`.

Cosmonic Control is built on [wasmCloud](https://wasmcloud.com/), an Incubating project at the [Cloud Native Computing Foundation (CNCF)](https://www.cncf.io/).

### Install local Kubernetes environment

For local Kubernetes development, we recommend [`kind`](https://kind.sigs.k8s.io/) with host ports 80 and 443 forwarded to Traefik's NodePorts (the Cosmonic Control chart deploys Traefik as the edge proxy by default):

```yaml
# kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 30080
        hostPort: 80
        protocol: TCP
      - containerPort: 30443
        hostPort: 443
        protocol: TCP
```

The following command downloads the `kind-config.yaml` from this repository and creates a cluster from it:

```shell
curl -fLO https://raw.githubusercontent.com/cosmonic-labs/control-demos/refs/heads/main/kind-config.yaml && kind create cluster --config=kind-config.yaml && rm kind-config.yaml
```

For other local Kubernetes environments (k3d, k3s) and cloud clusters, see the [Cosmonic Control documentation](https://docs.cosmonic.com/install-cosmonic-control).

## Install Cosmonic Control

Cosmonic Control is free to get started. Deploy it to Kubernetes with Helm, pre-creating a Traefik Ingress for this demo's host:

```shell
helm install cosmonic-control oci://ghcr.io/cosmonic/cosmonic-control \
  --version 0.4.1 \
  --namespace cosmonic-system \
  --create-namespace \
  --set 'ingress.hosts[0].host=petstore-mcp.localhost.cosmonic.sh'
```

Deploy a HostGroup:

```shell
helm install hostgroup oci://ghcr.io/cosmonic/cosmonic-control-hostgroup \
  --version 0.4.1 \
  --namespace cosmonic-system
```

## Deploy with Cosmonic Control

Deploy this component to a Kubernetes cluster with Cosmonic Control using the shared HTTP trigger chart:

```shell
helm install petstore-mcp ../../charts/http-trigger -f values.http-trigger.yaml
```

You can also deploy the chart as an OCI artifact with a remote values file:

```shell
helm install petstore-mcp --version 0.1.2 oci://ghcr.io/cosmonic-labs/charts/http-trigger -f https://raw.githubusercontent.com/cosmonic-labs/control-demos/refs/heads/main/petstore-mcp/values.http-trigger.yaml
```

## Running on Kubernetes

The MCP server will serve at [http://petstore-mcp.localhost.cosmonic.sh/v1/mcp](http://petstore-mcp.localhost.cosmonic.sh/v1/mcp)

If you'd like to debug your MCP server, you can start [the official MCP model inspector](https://github.com/modelcontextprotocol/inspector) via the following command:

```shell
npx @modelcontextprotocol/inspector
```

Configure the MCP model inspector's connection:

* Transport Type: **Streamable HTTP**
* URL: `http://petstore-mcp.localhost.cosmonic.sh/v1/mcp`
* Connection Type: **Via Proxy**

## Development

For source files and development information, see the MCP server template repository at [cosmonic-labs/mcp-server-template-ts](https://github.com/cosmonic-labs/mcp-server-template-ts) and the [MCP documentation for Cosmonic Control](https://cosmonic.com/docs/securely-deploy-mcp-on-kubernetes).
