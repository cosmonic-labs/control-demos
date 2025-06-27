# HTTP Server for Cosmonic Control

This is a simple HTTP server with multiple endpoints written in Go, implemented as a Wasm component and packaged for deployment to Kubernetes clusters with [Cosmonic Control](https://cosmonic.com/docs/).

The `.wasm` binary build output with any WebAssembly runtime that supports components and `wasi:http`.

## Deploy with Cosmonic Control

Deploy this template to a Kubernetes cluster with Cosmonic Control using the included Helm chart:

```shell
helm install http-server ./chart/http-server
```

The chart is also available as an OCI artifact:

```shell
helm install http-server oci://ghcr.io/cosmonic-labs/charts/http-server
```

## Contents

In addition to the standard elements of a Go project, the template directory includes the following files and directories:

- `build/`: Target directory for compiled `.wasm` binaries
- `chart/`: Helm chart
- `manifests/`: Example CRD deployment manifests for Kubernetes clusters with Cosmonic Control
- `wit/`: Directory for WebAssembly Interface Type (WIT) packages that define interfaces

## Build Dependencies

Before starting, ensure that you have the following installed in addition to the Go (1.23+) toolchain:

- [`tinygo`](https://tinygo.org/getting-started/install/) for compiling Go (always use the latest version)
- [`wasm-tools`](https://github.com/bytecodealliance/wasm-tools#installation) for Go bindings
- [`wash`](https://github.com/cosmonic-labs/wash) for building the component

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

The HTTP Server is accessible at localhost:8000. View the code and make changes in `main.go`.

### Send a request

You can send a request to the following endpoints:

**GET /**

Returns a list of available endpoints and their descriptions.

```shell
curl http://localhost:8000/
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
curl -v http://localhost:8000/error
```
```text
* Host localhost:8000 was resolved.
* IPv6: ::1
* IPv4: 127.0.0.1
*   Trying [::1]:8000...
* connect to ::1 port 8000 from ::1 port 51390 failed: Connection refused
*   Trying 127.0.0.1:8000...
* Connected to localhost (127.0.0.1) port 8000
> GET /error HTTP/1.1
> Host: localhost:8000
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
< connection: close
< transfer-encoding: chunked
< date: Thu, 19 Dec 2024 23:52:34 GMT
< 
Something went wrong
* Closing connection
```

**GET /headers**

Returns your User-Agent in the response headers.

```shell
curl -v http://localhost:8000/headers
```
```text
* Host localhost:8000 was resolved.
* IPv6: ::1
* IPv4: 127.0.0.1
*   Trying [::1]:8000...
* connect to ::1 port 8000 from ::1 port 51499 failed: Connection refused
*   Trying 127.0.0.1:8000...
* Connected to localhost (127.0.0.1) port 8000
> GET /headers HTTP/1.1
> Host: localhost:8000
> User-Agent: curl/8.7.1
> Accept: */*
> 
* Request completely sent off
< HTTP/1.1 200 OK
< x-your-user-agent: curl/8.7.1
< vary: origin, access-control-request-method, access-control-request-headers
< access-control-allow-origin: *
< access-control-expose-headers: *
< connection: close
< transfer-encoding: chunked
< date: Thu, 19 Dec 2024 23:53:49 GMT
< 
* Closing connection
Check headers!
```

**POST /form**

Echoes back form data from a POST request.

```shell
curl -X POST -d "field1=value1&field2=value2" http://localhost:8000/form
```
```text
field2: value2
field1: value1
```

**POST /post**

Echoes back the entire body of a POST request.

```shell
curl -X POST -d "Hello World" http://localhost:8000/post
```
```text
Hello World
```

### Clean Up

You can cancel the `wash dev` process with `Ctrl-C`.

## Building with `wash`

To build the component:

```shell
wash build
```

## Further Reading

To learn how to extend this example with additional capabilities, see the [Adding Capabilities](https://wasmcloud.com/docs/tour/adding-capabilities?lang=rust) section of the wasmCloud documentation.

For more on building components, see the [Component Developer Guide](https://wasmcloud.com/docs/developer/components/) in the wasmCloud documentation. 
