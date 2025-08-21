# Hono with Swagger UI for Cosmonic Control

This Wasm component is a tool for documenting and testing RESTful APIs, built on the [Hono HTTP framework](https://hono.dev/docs/) and the [Swagger UI](https://swagger.io/docs/open-source-tools/swagger-ui/usage/installation/) middleware. The component provides an interactive documentation interface based on a given OpenAPI specification. 

## Install Cosmonic Control

Sign up for Cosmonic Control's [free trial](https://cosmonic.com/trial) to get a `cosmonicLicenseKey`.

```bash
helm install cosmonic-control oci://ghcr.io/cosmonic/cosmonic-control --version 0.2.0 --namespace cosmonic-system --create-namespace --set cosmonicLicenseKey="<insert license here>"
```
```bash
helm install hostgroup oci://ghcr.io/cosmonic/cosmonic-control-hostgroup --version 0.2.0 --namespace cosmonic-system --set http.enabled=true
```

## Deploy with Cosmonic Control

Deploy this component to a Kubernetes cluster with Cosmonic Control using the shared HTTP sample chart:

```shell
helm install hono-swagger-ui ../../charts/http-sample -f values.yaml -n hono-swagger-ui --create-namespace
```

The chart is also available as an OCI artifact:

```shell
helm install hono-swagger-ui oci://ghcr.io/cosmonic-labs/charts/http-sample -f values.yaml -n hono-swagger-ui --create-namespace
```

## Running the Kubernetes demo

In a separate terminal tab:

```bash
kubectl -n cosmonic-system port-forward svc/hostgroup-default 9091:9091
```

Open browser to <http://localhost:9091/ui> to see the example.

![screenshot](./images/screenshot.png)

## Cleaning up

```bash
helm uninstall hono-swagger-ui -n hono-swagger-ui
```
```bash
kubectl delete ns hono-swagger-ui
```

## Contents

In addition to the standard elements of a TypeScript project, the directory includes the following files and directories:

- `values.yaml`: Helm values for the shared HTTP sample chart
- `wit/`: Directory for WebAssembly Interface Type (WIT) packages that define interfaces

## Building Locally

Before starting, ensure that you have the following installed:

- [`node` - NodeJS runtime](https://nodejs.org) (see `.nvmrc` for version)
- [`npm` - Node Package Manager (NPM)](https://github.com/npm/cli) manages packages for the NodeJS ecosystem
- [`wash` - Wasm Shell](https://github.com/wasmCloud/wash) for developing and building components

### Developing with `wash`

Clone the [cosmonic-labs/control-demos repository](https://github.com/cosmonic-labs/control-demos): 

```shell
git clone https://github.com/cosmonic-labs/control-demos.git
```

Change directory to `hono-swagger-ui`:

```shell
cd hono-swagger-ui
```

Start a development loop:

```shell
wash dev
```

or

```shell
npm run start
```

Navigate to [127.0.0.1:8000](http://127.0.0.1:8000).
