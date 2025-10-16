# "Hello World" in Rust for Cosmonic Control

This is a simple Rust-based WebAssembly (Wasm) component intended to run on [Cosmonic Control](https://cosmonic.com/), an enterprise control plane for managing WebAssembly (Wasm) workloads in cloud native environments. The component responds with a "Hello World" message for each request. 

While this component was written for Cosmonic Control, you can run it with any WebAssembly runtime that supports the Component Model and the [WebAssembly System Interface (WASI)](https://wasi.dev/) HTTP API. The component is available as an OCI artifact at `ghcr.io/cosmonic-labs/control-demos/hello-world`.

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
helm install hello-world ../../charts/http-trigger -f values.http-trigger.yaml
```

You can also deploy the chart as an OCI artifact with a remote values file:

```shell
helm install hello-world --version 0.1.2 oci://ghcr.io/cosmonic-labs/charts/http-trigger -f https://raw.githubusercontent.com/cosmonic-labs/control-demos/refs/heads/main/hello-world/values.http-trigger.yaml
```

## Running on Kubernetes

Connect to the component at <hello-world.localhost.cosmonic.sh>:

```shell
curl hello-world.localhost.cosmonic.sh
```

## Contents

In addition to the standard elements of a Rust project, the template directory includes the following files and directories:

- `wit/`: Directory for WebAssembly Interface Type (WIT) packages that define interfaces

There is also a GitHub Workflow `hello-world.yml` in the `.github/workflows` directory at the root of `control-demos` that is triggered on release. This workflow uses the [`setup-wash` GitHub Action](https://github.com/wasmCloud/setup-wash-action) to build the component and push an OCI artifact to GHCR. The workflow should work in your own fork and can be adapted for other Rust-based Wasm components with minimal changes. 

## Build Dependencies

Before starting, ensure that you have the following installed:

- [`cargo`](https://www.rust-lang.org/tools/install) 1.82+ for the Rust toolchain
- [Wasm Shell (`wash`)](https://github.com/wasmCloud/wash) for component development

### Developing with `wash`

Clone the [cosmonic-labs/control-demos repository](https://github.com/cosmonic-labs/control-demos): 

```shell
git clone https://github.com/cosmonic-labs/control-demos.git
```

Change directory to `hello-world`:

```shell
cd hello-world
```

Start a development loop:

```shell
wash dev
```

The component is accessible at localhost:8000. View the code and make changes in `src/lib.rs`.

### Clean Up

You can cancel the `wash dev` process with `Ctrl-C`.

## Building with `wash`

To build the component:

```shell
wash build
```

## Further Reading

For more on building components, see the [Developer Guide](https://cosmonic.com/docs/developer-guide/developing-webassembly-components) in the Cosmonic Control documentation. 

To learn how to extend this example with additional capabilities, see the [Adding Capabilities](https://wasmcloud.com/docs/tour/adding-capabilities?lang=rust) section of the wasmCloud documentation.