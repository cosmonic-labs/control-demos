# Blobstore Demo (NATS) for Cosmonic Control

This is a Wasm component that performs a variety of blob storage operations and exposes the results via HTTP. The example is written in Rust, implemented as a Wasm component, and packaged for deployment to Kubernetes clusters with [Cosmonic Control](https://cosmonic.com/docs/). 

While this component was written for Cosmonic Control, you can run it with any WebAssembly runtime that supports the Component Model and the [WebAssembly System Interface (WASI)](https://wasi.dev/) HTTP and Blobstore APIs. The component is available as an OCI artifact at `ghcr.io/cosmonic-labs/control-demos/blobstore`.

When deployed on Cosmonic Control with the manifests or Helm chart in this repository, the component is backed by NATS file storage, but it could use other forms of blob storage (such as S3) via the standard `wasi:blobstore` API.

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
  --set 'ingress.hosts[0].host=blobstore.localhost.cosmonic.sh'
```

Deploy a HostGroup:

```shell
helm install hostgroup oci://ghcr.io/cosmonic/cosmonic-control-hostgroup \
  --version 0.4.1 \
  --namespace cosmonic-system
```

## Deploy with Cosmonic Control

Deploy this demo to a Kubernetes cluster with Cosmonic Control using the shared HTTP trigger chart:

```shell
helm install blobstore-nats ../../charts/http-trigger -f values.yaml
```

You can also deploy the chart as an OCI artifact with a remote values file:

```shell
helm install blobstore-nats --version 0.1.2 oci://ghcr.io/cosmonic-labs/charts/http-trigger -f https://raw.githubusercontent.com/cosmonic-labs/control-demos/refs/heads/main/blobstore-nats/values.http-trigger.yaml
```

## Contents

In addition to the standard elements of a Rust project, the template directory includes the following files and directories:

- `wit/`: Directory for WebAssembly Interface Type (WIT) packages that define interfaces

## Build Dependencies

Before starting, ensure that you have the following installed:

- [`cargo`](https://www.rust-lang.org/tools/install) 1.82+ for the Rust toolchain
- `wasm32-wasip2` target for Rust: Install with `rustup target add wasm32-wasip2`
- [Wasm Shell (`wash`)](https://github.com/wasmCloud/wash) rc.6 for component development

## Developing with `wash`

Clone the [cosmonic-labs/control-demos repository](https://github.com/cosmonic-labs/control-demos): 

```shell
git clone https://github.com/cosmonic-labs/control-demos.git
```

Change directory to `blobstore-nats`:

```shell
cd blobstore-nats
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

## What it does

The component performs a series of blobstore operations:

1. Container Operations:
   - Creates two containers (default: "ying" and "yang")
   - Verifies container existence
   - Retrieves container metadata

2. Basic Blob Operations:
   - Writes four blobs ("earth", "air", "fire", "water") to "ying" container
   - Reads back and verifies content
   - Demonstrates partial content reading (first 4 bytes)

3. Advanced Operations:
   - Moves "fire" from "ying" to "yang" container
   - Copies "water" from "ying" to "yang" container
   - Lists objects in both containers
   - Cleans up by clearing "ying" container

## Test the component

Once deployed, run the component by issuing the following command:

```bash
curl http://localhost:8080
```

The component will return a JSON response showing the results of all operations:

```json
{
  "container_ops": {
    "create_container": {
      "success": true,
      "message": "Created ying",
      "timestamp": "2024-12-05 16:30:00 UTC"
    },
    "container_info": {
      "success": true,
      "message": "Container ying created at 2024-12-05 16:30:00 UTC",
      "timestamp": "2024-12-05 16:30:00 UTC"
    }
    // ... more container operations
  },
  "blob_ops": {
    "write_blob": {
      "success": true,
      "message": "Wrote earth to ying",
      "timestamp": "2024-12-05 16:30:01 UTC"
    }
    // ... more blob operations
  },
  "container_names": ["ying", "yang"]
}
```

## Further Reading

For more on building components, see the [Developer Guide](https://cosmonic.com/docs/developer-guide/developing-webassembly-components) in the Cosmonic Control documentation. 

To learn how to extend this example with additional capabilities, see the [Adding Capabilities](https://wasmcloud.com/docs/tour/adding-capabilities?lang=rust) section of the wasmCloud documentation.
