# Welcome Tour for Cosmonic Control

This Wasm component introduces users to the core features of Cosmonic Control. It is built on [Hono](https://hono.dev) and based on the [HTTP Server with Hono wasmCloud example](https://github.com/wasmCloud/typescript/tree/main/examples/components/http-server-with-hono).

The component serves a simple web app that embeds assets like fonts and images directly in the HTML.

It also uses `wasi:config/runtime` to pass config from the environment to the Hono app for values such as the Console UI address.

## Install Cosmonic Control

Sign-up for Cosmonic Control's [free trial](https://cosmonic.com/trial) to get a `cosmonicLicenseKey`.

```bash
helm install cosmonic-control oci://ghcr.io/cosmonic/cosmonic-control --version 0.2.0 --namespace cosmonic-system --create-namespace --set cosmonicLicenseKey="<insert license here>"

helm install hostgroup oci://ghcr.io/cosmonic/cosmonic-control-hostgroup --version 0.2.0 --namespace cosmonic-system --set http.enabled=true
```

## Deploy with Cosmonic Control

Deploy this template to a Kubernetes cluster with Cosmonic Control using the included Helm chart:

```shell
helm install welcome-tour ./chart/welcome-tour -n welcome-app --create-namespace
```

The chart is also available as an OCI artifact:

```shell
helm install welcome-tour oci://ghcr.io/cosmonic-labs/charts/welcome-tour -n welcome-app --create-namespace --version 0.1.0
```

## Running the Kubernetes demo

In separate terminal tabs:

```bash
kubectl -n cosmonic-system port-forward svc/console 8080:8080

kubectl -n cosmonic-system port-forward svc/hostgroup-default 9091:9091
```

Open browser to <http://localhost:9091> to see the tour!

See some of the resources running with:

```bash
kubectl get hosts
kubectl get components -A
kubectl get providers -A
```

## Cleaning up

```bash
helm uninstall welcome-tour -n welcome-app
kubectl delete ns welcome-app

helm uninstall hostgroup -n cosmonic-system
helm uninstall cosmonic-control -n cosmonic-system
kubectl delete ns cosmonic-system
```

## Contents

In addition to the standard elements of a TypeScript project, the directory includes the following files and directories:

- `chart/`: Helm chart
- `manifests/`: Example CRD deployment manifests for Kubernetes clusters with Cosmonic Control
- `wit/`: Directory for WebAssembly Interface Type (WIT) packages that define interfaces

## Building Locally

Before starting, ensure that you have the following installed:

- [`node` - NodeJS runtime](https://nodejs.org) (see `.nvmrc` for version)
- [`npm` - Node Package Manager (NPM)](https://github.com/npm/cli) manages packages for the NodeJS ecosystem
- [`wash` - Wasm Shell](https://github.com/cosmonic-labs/wash) for developing and building components

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
