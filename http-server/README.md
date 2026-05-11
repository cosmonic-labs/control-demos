# HTTP Server for Cosmonic Control

This is a simple HTTP server with multiple endpoints written in Go, implemented as a Wasm component and packaged for deployment to Kubernetes clusters with [Cosmonic Control](https://cosmonic.com/docs/).

The `.wasm` binary build output with any WebAssembly runtime that supports components and `wasi:http`.

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
  --set 'ingress.hosts[0].host=http-server.localhost.cosmonic.sh'
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
helm install http-server ../../charts/http-trigger -f values.http-trigger.yaml
```

You can also deploy the chart as an OCI artifact with a remote values file:

```shell
helm install http-server --version 0.1.2 oci://ghcr.io/cosmonic-labs/charts/http-trigger -f https://raw.githubusercontent.com/cosmonic-labs/control-demos/refs/heads/main/http-server/values.http-trigger.yaml
```

## Running on Kubernetes

Connect to the component at `http-server.localhost.cosmonic.sh`.

```shell
curl http-server.localhost.cosmonic.sh
```

### Send a request

You can send a request to the following endpoints:

**GET /**

Returns a list of available endpoints and their descriptions.

```shell
curl http://http-server.localhost.cosmonic.sh/
```
```text
  /error - return a 500 error
  /form - echo the fields of a POST request
  /headers - echo your user agent back as a server side header
  /post - echo the body of a POST request
```

**GET /error**

Returns a 500 Internal Server Error.

```shell
curl -v http://http-server.localhost.cosmonic.sh/error
```
```text
* Host http-server.localhost.cosmonic.sh:80 was resolved.
* IPv6: (none)
* IPv4: 127.0.0.1
*   Trying 127.0.0.1:80...
* Connected to http-server.localhost.cosmonic.sh (127.0.0.1) port 80
> GET / HTTP/1.1
> Host: http-server.localhost.cosmonic.sh
> User-Agent: curl/8.7.1
> Accept: */*
> 
* Request completely sent off
< HTTP/1.1 200 OK
< content-type: text/plain
< x-requested-path: /
< x-existing-paths: /error,/form,/headers,/post
< date: Thu, 23 Oct 2025 12:08:03 GMT
< x-envoy-upstream-service-time: 1
< server: envoy
< transfer-encoding: chunked
< 
/error - return a 500 error
  /form - echo the fields of a POST request
  /headers - echo your user agent back as a server side header
* Connection #0 to host http-server.localhost.cosmonic.sh left intact
  /post - echo the body of a POST request% 
```

**GET /headers**

Returns your User-Agent in the response headers.

```shell
curl -v http://http-server.localhost.cosmonic.sh/headers
```
```text
* Host http-server.localhost.cosmonic.sh:80 was resolved.
* IPv6: (none)
* IPv4: 127.0.0.1
*   Trying 127.0.0.1:80...
* Connected to http-server.localhost.cosmonic.sh (127.0.0.1) port 80
> GET /headers HTTP/1.1
> Host: http-server.localhost.cosmonic.sh
> User-Agent: curl/8.7.1
> Accept: */*
> 
* Request completely sent off
< HTTP/1.1 200 OK
< x-your-user-agent: curl/8.7.1
< date: Thu, 23 Oct 2025 12:10:17 GMT
< x-envoy-upstream-service-time: 2
< server: envoy
< transfer-encoding: chunked
< 
* Connection #0 to host http-server.localhost.cosmonic.sh left intact
Check headers!
```

**POST /form**

Echoes back form data from a POST request.

```shell
curl -X POST -d "field1=value1&field2=value2" http://http-server.localhost.cosmonic.sh/form
```
```text
field2: value2
field1: value1
```

**POST /post**

Echoes back the entire body of a POST request.

```shell
curl -X POST -d "Hello World" http://http-server.localhost.cosmonic.sh/post
```
```text
Hello World
```

## Contents

In addition to the standard elements of a Go project, the template directory includes the following files and directories:

- `build/`: Target directory for compiled `.wasm` binaries
- `values.yaml`: Helm values for the shared HTTP sample chart
- `manifests/`: Example CRD deployment manifests for Kubernetes clusters with Cosmonic Control
- `wit/`: Directory for WebAssembly Interface Type (WIT) packages that define interfaces

## Building Locally

Before starting, ensure that you have the following installed in addition to the Go (1.23+) toolchain:

- [`tinygo`](https://tinygo.org/getting-started/install/) for compiling Go (always use the latest version)
- [`wasm-tools`](https://github.com/bytecodealliance/wasm-tools#installation) for Go bindings
- [`wash`](https://github.com/wasmCloud/wash) rc.6 for building the component

### Developing with `wash`

Clone the [cosmonic-labs/control-demos repository](https://github.com/cosmonic-labs/control-demos): 

```shell
git clone https://github.com/cosmonic-labs/control-demos.git
```

Change directory to `http-server`:

```shell
cd http-server
```

Start a development loop:

```shell
wash dev
```

When using `wash dev`, the HTTP Server is accessible at localhost:8000. View the code and make changes in `main.go`.

You can cancel the `wash dev` process with `Ctrl-C`.

## Building with `wash`

To build the component:

```shell
wash build
```

## Further Reading

To learn how to extend this example with additional capabilities, see the [Adding Capabilities](https://wasmcloud.com/docs/tour/adding-capabilities?lang=rust) section of the wasmCloud documentation.

For more on building components, see the [Component Developer Guide](https://wasmcloud.com/docs/developer/components/) in the wasmCloud documentation. 
