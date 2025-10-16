# Petstore MCP Server for Cosmonic Control

This Wasm component is an example of an MCP server compiled to a secure-by-default Wasm sandbox, enabling MCP hosts to utilize the [Swagger PetStore API](https://petstore3.swagger.io/api/v3/openapi.json). The example is written in TypeScript and packaged for deployment to Kubernetes clusters with [Cosmonic Control](https://cosmonic.com/docs/). 

While this component was written for Cosmonic Control, you can run it with any WebAssembly runtime that supports the Component Model and the [WebAssembly System Interface (WASI)](https://wasi.dev/) HTTP API. The component is available as an OCI artifact at `ghcr.io/cosmonic-labs/petstore-mcp-server`.

Cosmonic Control is built on [wasmCloud](https://wasmcloud.com/), an Incubating project at the [Cloud Native Computing Foundation (CNCF)](https://www.cncf.io/).

## Install local Kubernetes environment

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

## Install Cosmonic Control

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

## Deploy with Cosmonic Control

Deploy this component to a Kubernetes cluster with Cosmonic Control using the shared HTTP trigger chart:

```shell
helm install hono-swagger-ui ../../charts/http-trigger -f values.http-trigger.yaml
```

You can also deploy the chart as an OCI artifact with a remote values file:

```shell
helm install hono-swagger-ui --version 0.1.2 oci://ghcr.io/cosmonic-labs/charts/http-trigger -f https://raw.githubusercontent.com/cosmonic-labs/control-demos/refs/heads/main/petstore-mcp/values.http-trigger.yaml
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
