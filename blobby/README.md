# Blobstore Fileserver ("Blobby") for Cosmonic Control

This is a Wasm component that acts as a file server for a blob storage solution, showing the basic CRUD operations of the `wasi:blobstore` contract. The example is written in Rust, implemented as a Wasm component, and packaged for deployment to Kubernetes clusters with [Cosmonic Control](https://cosmonic.com/docs/). 

While this component was written for Cosmonic Control, you can run it with any WebAssembly runtime that supports the Component Model and the [WebAssembly System Interface (WASI)](https://wasi.dev/) HTTP and Blobstore APIs. The component is available as an OCI artifact at `ghcr.io/cosmonic-labs/control-demos/blobstore`.

When deployed on Cosmonic Control with the manifests or Helm chart in this repository, the component is backed by NATS file storage, but it could use other forms of blob storage (such as S3) via the standard `wasi:blobstore` API.

Cosmonic Control is built on [wasmCloud](https://wasmcloud.com/), an Incubating project at the [Cloud Native Computing Foundation (CNCF)](https://www.cncf.io/).

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

Deploy this demo to a Kubernetes cluster with Cosmonic Control and NATS using the shared HTTP trigger chart:

```shell
helm install blobby ../../charts/http-trigger -f values.http-trigger.yaml
```

The chart is also available as an OCI artifact:

```shell
helm install blobby --version 0.1.2 oci://ghcr.io/cosmonic-labs/charts/http-trigger -f https://raw.githubusercontent.com/cosmonic-labs/control-demos/refs/heads/main/blobby/values.http-trigger.yaml
```

## Development

Find the [source for this component in the wasmCloud repository](https://github.com/wasmCloud/wasmCloud/tree/main/examples/rust/components/blobby).

Before starting, ensure that you have the following installed:

- [`cargo`](https://www.rust-lang.org/tools/install) 1.82+ for the Rust toolchain
- `wasm32-wasip2` target for Rust: Install with `rustup target add wasm32-wasip2`
- [Wasm Shell (`wash`)](https://github.com/wasmCloud/wash) rc.6 for component development

### Developing with `wash`

Clone the [wasmCloud repository](https://github.com/wasmcloud/wasmcloud): 

```shell
git clone https://github.com/wasmCloud/wasmcloud.git
```

Change directory to `blobby`:

```shell
cd wasmcloud/examples/rust/components/blobby
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

This component uses the following interfaces:

1. `wasi:http` to receive http requests
2. `wasi:blobstore` to save the image to a blob
3. `wasi:logging` so the component can log

## Web UI

A static web interface is available in `index.html` for interacting with the blobby storage system through a user-friendly UI. The interface provides:

- **File Upload**: Upload single or multiple files to the blob storage
- **File Download**: Download stored files with a single click
- **File Deletion**: Remove files from storage
- **Configurable API URL**: Change the blobby API endpoint (defaults to `http://127.0.0.1:8000`)

To use the web UI:

1. Start the blobby service (using `wash dev` or deployed to Kubernetes)
2. Open `index.html` in a web browser
3. Configure the API URL if different from the default
4. Start uploading, downloading, and managing files

The UI is built with vanilla HTML, CSS, and JavaScript with no external dependencies. Files are tracked client-side using browser localStorage.

## API Usage

Once everything is up and running, you can run through all of the operations by following the
annotated commands below:

```console
# Create a file with some content
$ echo 'Hello there!' > myfile.txt

# Upload the file to the fileserver
$ curl -H 'Content-Type: text/plain' -v 'http://127.0.0.1:8000/myfile.txt' --data-binary @myfile.txt
*   Trying 127.0.0.1:8000...
* Connected to 127.0.0.1 (127.0.0.1) port 8000 (#0)
> POST /myfile.txt HTTP/1.1
> Host: 127.0.0.1:8000
> User-Agent: curl/7.85.0
> Accept: */*
> Content-Type: text/plain
> Content-Length: 12
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< content-length: 0
< date: Wed, 18 Jan 2023 23:12:56 GMT
<
* Connection #0 to host 127.0.0.1 left intact

# Get the file back from the server
$ curl -v 'http://127.0.0.1:8000/myfile.txt'
*   Trying 127.0.0.1:8000...
* Connected to 127.0.0.1 (127.0.0.1) port 8000 (#0)
> GET /myfile.txt HTTP/1.1
> Host: 127.0.0.1:8000
> User-Agent: curl/7.85.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< content-length: 13
< date: Wed, 18 Jan 2023 23:24:24 GMT
<
Hello there!
* Connection #0 to host 127.0.0.1 left intact

# Update the file
$ echo 'General Kenobi!' >> myfile.txt
$ curl -H 'Content-Type: text/plain' -v 'http://127.0.0.1:8000/myfile.txt' --data-binary @myfile.txt
*   Trying 127.0.0.1:8000...
* Connected to 127.0.0.1 (127.0.0.1) port 8000 (#0)
> POST /myfile.txt HTTP/1.1
> Host: 127.0.0.1:8000
> User-Agent: curl/7.85.0
> Accept: */*
> Content-Type: text/plain
> Content-Length: 29
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< content-length: 0
< date: Wed, 18 Jan 2023 23:25:18 GMT
<
* Connection #0 to host 127.0.0.1 left intact

# Get the file again to see your updates
$ curl -v 'http://127.0.0.1:8000/myfile.txt'
*   Trying 127.0.0.1:8000...
* Connected to 127.0.0.1 (127.0.0.1) port 8000 (#0)
> GET /myfile.txt HTTP/1.1
> Host: 127.0.0.1:8000
> User-Agent: curl/7.85.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< content-length: 29
< date: Wed, 18 Jan 2023 23:26:17 GMT
<
Hello there!
General Kenobi!
* Connection #0 to host 127.0.0.1 left intact

# Delete the file
$ curl -X DELETE -v 'http://127.0.0.1:8000/myfile.txt'
*   Trying 127.0.0.1:8000...
* Connected to 127.0.0.1 (127.0.0.1) port 8000 (#0)
> DELETE /myfile.txt HTTP/1.1
> Host: 127.0.0.1:8000
> User-Agent: curl/7.85.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< content-length: 0
< date: Wed, 18 Jan 2023 23:33:02 GMT
<
* Connection #0 to host 127.0.0.1 left intact

# (Optional) See that the file doesn't exist anymore
$ curl -v 'http://127.0.0.1:8000/myfile.txt'
*   Trying 127.0.0.1:8000...
* Connected to 127.0.0.1 (127.0.0.1) port 8000 (#0)
> GET /myfile.txt HTTP/1.1
> Host: 127.0.0.1:8000
> User-Agent: curl/7.85.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 404 Not Found
< content-length: 0
< date: Wed, 18 Jan 2023 23:39:07 GMT
<
* Connection #0 to host 127.0.0.1 left intact
```
