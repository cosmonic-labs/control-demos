# HTTP Server for Cosmonic Control

This is a simple HTTP server with multiple endpoints written in Go, implemented as a Wasm component and packaged for deployment to Kubernetes clusters with [Cosmonic Control](https://cosmonic.com/docs/).

The `.wasm` binary build output with any WebAssembly runtime that supports components and `wasi:http`.

## Install Cosmonic Control

Sign-up for Cosmonic Control's [free trial](https://cosmonic.com/trial) to get a `cosmonicLicenseKey`.

```shell
helm install cosmonic-control oci://ghcr.io/cosmonic/cosmonic-control --version 0.2.0 --namespace cosmonic-system --create-namespace --set cosmonicLicenseKey="<insert license here>"
```

Install a HostGroup with HTTP enabled:

```shell
helm install hostgroup oci://ghcr.io/cosmonic/cosmonic-control-hostgroup --version 0.2.0 --namespace cosmonic-system --set http.enabled=true
```

## Deploy with Cosmonic Control

Deploy this component to a Kubernetes cluster with Cosmonic Control using the shared HTTP sample chart:

```shell
helm install http-server ../../charts/http-sample -f values.yaml
```

The chart is also available as an OCI artifact:

```shell
helm install http-server oci://ghcr.io/cosmonic-labs/charts/http-sample -f values.yaml
```

## Running on Kubernetes

Port-forward the component:

```shell
kubectl -n cosmonic-system port-forward svc/hostgroup-default 9091:9091
```

Now you can connect to the component at `localhost:9091`.

### Send a request

You can send a request to the following endpoints:

**GET /**

Returns a list of available endpoints and their descriptions.

```shell
curl http://localhost:9091/
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
curl -v http://localhost:9091/error
```
```text
* Host localhost:9091 was resolved.
* IPv6: ::1
* IPv4: 127.0.0.1
*   Trying [::1]:9091...
* Connected to localhost (::1) port 9091
> GET /error HTTP/1.1
> Host: localhost:9091
> User-Agent: curl/8.7.1
> Accept: */*
>
* Request completely sent off
< HTTP/1.1 500 Internal Server Error
< content-type: text/plain; charset=utf-8
< x-content-type-options: nosniff
< vary: origin, access-control-request-method, access-control-request-headers
< access-control-allow-origin: *
< access-control-expose-headers: *
< transfer-encoding: chunked
< date: Thu, 17 Jul 2025 14:10:53 GMT
<
Something went wrong
* Connection #0 to host localhost left intact
```

**GET /headers**

Returns your User-Agent in the response headers.

```shell
curl -v http://localhost:9091/headers
```
```text
* Host localhost:9091 was resolved.
* IPv6: ::1
* IPv4: 127.0.0.1
*   Trying [::1]:9091...
* Connected to localhost (::1) port 9091
> GET /headers HTTP/1.1
> Host: localhost:9091
> User-Agent: curl/8.7.1
> Accept: */*
>
* Request completely sent off
< HTTP/1.1 200 OK
< x-your-user-agent: curl/8.7.1
< vary: origin, access-control-request-method, access-control-request-headers
< access-control-allow-origin: *
< access-control-expose-headers: *
< transfer-encoding: chunked
< date: Thu, 17 Jul 2025 14:09:59 GMT
<
* Connection #0 to host localhost left intact
Check headers!
```

**POST /form**

Echoes back form data from a POST request.

```shell
curl -X POST -d "field1=value1&field2=value2" http://localhost:9091/form
```
```text
field2: value2
field1: value1
```

**POST /post**

Echoes back the entire body of a POST request.

```shell
curl -X POST -d "Hello World" http://localhost:9091/post
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
- [`wash`](https://github.com/wasmCloud/wash) for building the component

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
