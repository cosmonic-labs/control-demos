# Blobstore Fileserver (NATS) for Cosmonic Control

This is a Wasm component that acts as a file server for a blob storage solution, showing the basic CRUD operations of the `wasi:blobstore` contract. The example is written in Rust, implemented as a Wasm component, and packaged for deployment to Kubernetes clusters with [Cosmonic Control](https://cosmonic.com/docs/). 

While this component was written for Cosmonic Control, you can run it with any WebAssembly runtime that supports the Component Model and the [WebAssembly System Interface (WASI)](https://wasi.dev/) HTTP and Blobstore APIs. The component is available as an OCI artifact at `ghcr.io/cosmonic-labs/control-demos/blobstore`.

When deployed on Cosmonic Control with the manifests or Helm chart in this repository, the component is backed by NATS file storage, but it could use other forms of blob storage (such as S3) via the standard `wasi:blobstore` API.

Cosmonic Control is built on [wasmCloud](https://wasmcloud.com/), an Incubating project at the [Cloud Native Computing Foundation (CNCF)](https://www.cncf.io/).

## Install Cosmonic Control

Sign up for Cosmonic Control's [free trial](https://cosmonic.com/trial) to get a `cosmonicLicenseKey`.

```shell
helm install cosmonic-control oci://ghcr.io/cosmonic/cosmonic-control --version 0.2.0 --namespace cosmonic-system --create-namespace --set cosmonicLicenseKey="<insert license here>"
```

Install a HostGroup with HTTP enabled:  

```shell
helm install hostgroup oci://ghcr.io/cosmonic/cosmonic-control-hostgroup --version 0.2.0 --namespace cosmonic-system --set http.enabled=true
```

## Deploy with Cosmonic Control

You will need a NATS installation on your Kubernetes cluster. Add the NATS repository to Helm:

```shell
helm repo add nats https://nats-io.github.io/k8s/helm/charts/
```

Install the NATS Helm chart with the `values.yaml` file below:

```shell
helm install nats nats/nats -f nats-values.yaml
```
```yaml
enabled: true
fullnameOverride: "nats"
nameOverride: "nats"
config:
  cluster:
    enabled: true
    replicas: 3
  leafnodes:
    enabled: true
  websocket:
    enabled: true
    port: 4223
  jetstream:
    enabled: true
    fileStore:
      pvc:
        size: 10Gi
    merge:
      domain: default
```

Deploy this demo to a Kubernetes cluster with Cosmonic Control and NATS using the shared HTTP trigger chart:

```shell
helm install blobby ../../charts/http-trigger -f values.http-trigger.yaml
```

The chart is also available as an OCI artifact:

```shell
helm install blobby --version 0.1.2 oci://ghcr.io/cosmonic-labs/charts/http-trigger -f values.http-trigger.yaml
```

## Build Dependencies

Before starting, ensure that you have the following installed:

- [`cargo`](https://www.rust-lang.org/tools/install) 1.82+ for the Rust toolchain
- `wasm32-wasip2` target for Rust: Install with `rustup target add wasm32-wasip2`
- [Wasm Shell (`wash`)](https://github.com/wasmCloud/wash) for component development

### Developing with `wash`

Clone the [cosmonic-labs/control-demos repository](https://github.com/cosmonic-labs/control-demos): 

```shell
git clone https://github.com/cosmonic-labs/control-demos.git
```

Change directory to `blobby`:

```shell
cd blobby
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
