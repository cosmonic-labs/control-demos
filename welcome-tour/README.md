# Welcome Tour for Cosmonic Control

This Wasm component introduces users to the core features of Cosmonic Control. It is built on [Hono](https://hono.dev) and based on the [HTTP Server with Hono wasmCloud example](https://github.com/wasmCloud/typescript/tree/main/examples/components/http-server-with-hono).

The component serves a web app that embeds all assets (fonts, images, SVGs) directly in the binary — no runtime file loading required. It guides users through deploying another component (Blobby), viewing metrics in Perses, and exploring further resources.

### Install local Kubernetes environment

For the best local Kubernetes development experience, we recommend installing [`k3d`](https://k3d.io/) and starting a cluster with the following command:

```shell
k3d cluster create cosmonic --port "80:80@loadbalancer" --k3s-arg "--disable=traefik@server:0"
```

For instructions on deploying to other local or cloud Kubernetes environments, see the [Cosmonic Control documentation](https://docs.cosmonic.com/install-cosmonic-control).

## Install Cosmonic Control

Deploy Cosmonic Control to Kubernetes with Helm:

```shell
helm install cosmonic-control oci://ghcr.io/cosmonic/cosmonic-control \
  --version 0.3.0 \
  --namespace cosmonic-system \
  --create-namespace \
  --set envoy.service.type=LoadBalancer
```

Deploy a HostGroup:

```shell
helm install hostgroup oci://ghcr.io/cosmonic/cosmonic-control-hostgroup --version 0.3.0 --namespace cosmonic-system
```

## Deploy with Cosmonic Control

Deploy this component to a Kubernetes cluster with Cosmonic Control using the shared HTTP trigger chart:

```shell
helm install welcome-tour ../charts/http-trigger -f values.http-trigger.yaml
```

You can also deploy the chart as an OCI artifact with a remote values file:

```shell
helm install welcome-tour --version 0.1.2 oci://ghcr.io/cosmonic-labs/charts/http-trigger -f https://raw.githubusercontent.com/cosmonic-labs/control-demos/refs/heads/main/welcome-tour/values.http-trigger.yaml
```

## Running the Kubernetes demo

Open browser to <http://welcome-tour.localhost.cosmonic.sh> to see the tour.

## Cleaning up

```bash
helm uninstall welcome-tour
```
```bash
helm uninstall hostgroup -n cosmonic-system
```
```bash
helm uninstall cosmonic-control -n cosmonic-system
```
```bash
kubectl delete ns cosmonic-system
```

## Contents

In addition to the standard elements of a TypeScript project, the directory includes the following files and directories:

- `values.http-trigger.yaml`: Helm values for the shared HTTP trigger chart
- `nodemon.json`: Configures `nodemon` to watch `src/` and re-run `wash dev` on changes
- `logo-wasmCloud.svg`: wasmCloud wordmark embedded as a base64 data URI in the footer
- `cosmonic-control.png`: Cosmonic Control logo embedded as a base64 data URI in the header
- `wit/`: Directory for WebAssembly Interface Type (WIT) packages that define interfaces

## Building Locally

Before starting, ensure that you have the following installed:

- [`node` - NodeJS runtime](https://nodejs.org) (see `.nvmrc` for version)
- [`npm` - Node Package Manager (NPM)](https://github.com/npm/cli) manages packages for the NodeJS ecosystem
- [`wash` - wasmCloud Shell](https://github.com/wasmCloud/wash) for developing and building components

### Developing with `wash`

Clone the [cosmonic-labs/control-demos repository](https://github.com/cosmonic-labs/control-demos):

```shell
git clone https://github.com/cosmonic-labs/control-demos.git
```

Change directory to `welcome-tour`:

```shell
cd welcome-tour
```

Install dependencies and start a development loop with file watching:

```shell
npm install && npm run dev
```

Or start `wash dev` directly without file watching:

```shell
wash dev
```

Navigate to [127.0.0.1:8000](http://127.0.0.1:8000).
