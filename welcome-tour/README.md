# Welcome Tour for Cosmonic Control

This Wasm component introduces users to the core features of Cosmonic Control. It is built on [Hono](https://hono.dev) and based on the [HTTP Server with Hono wasmCloud example](https://github.com/wasmCloud/typescript/tree/main/examples/components/http-server-with-hono).

The component serves a simple web app that embeds assets like fonts and images directly in the HTML.

It also uses `wasi:config/runtime` to pass config from the environment to the Hono app for values such as the Console UI address.

### Install local Kubernetes environment

For the best local Kubernetes development experience, we recommend installing [`kind`](https://kind.sigs.k8s.io/) and starting a cluster with the following `kind-config.yaml` configuration, enabling simple local ingress with Envoy:

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

The following command downloads the `kind-config.yaml` from this repository, starts a cluster, and deletes the config upon completion:

```shell
curl -fLO https://raw.githubusercontent.com/cosmonic-labs/control-demos/refs/heads/main/kind-config.yaml && kind create cluster --config=kind-config.yaml && rm kind-config.yaml
```

## Install Cosmonic Control

You'll need a **trial license key** to follow these instructions. Sign up for Cosmonic Control's [free trial](https://cosmonic.com/trial) to get a key.

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
helm install welcome-tour ../../charts/http-trigger -f values.http-trigger.yaml
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

- `values.yaml`: Helm values for the shared HTTP sample chart
- `wit/`: Directory for WebAssembly Interface Type (WIT) packages that define interfaces

## Building Locally

Before starting, ensure that you have the following installed:

- [`node` - NodeJS runtime](https://nodejs.org) (see `.nvmrc` for version)
- [`npm` - Node Package Manager (NPM)](https://github.com/npm/cli) manages packages for the NodeJS ecosystem
- [`wash` - Wasm Shell](https://github.com/wasmCloud/wash) rc.6 for developing and building components

### Developing with `wash`

Clone the [cosmonic-labs/control-demos repository](https://github.com/cosmonic-labs/control-demos): 

```shell
git clone https://github.com/cosmonic-labs/control-demos.git
```

Change directory to `welcome-tour`:

```shell
cd welcome-tour
```

Start a development loop:

```shell
wash dev --runtime-config consoleurl=http://127.0.0.1:8000
```

or

```shell
npm run start
```

Navigate to [127.0.0.1:8000](http://127.0.0.1:8000).
