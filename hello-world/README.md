# "Hello World" for Cosmonic Control

This is a simple Rust-based WebAssembly application intended as a simple "Hello world" introduction for Cosmonic Control. 

While this was written for Cosmonic Control, you can run it with any WebAssembly runtime that supports components and WASI HTTP.

## Running with Cosmonic Control

You can deploy this application to a Kubernetes cluster with [Cosmonic Control]() using the included Helm chart:

```shell
helm install hello-world ./chart/hello-world
```

The chart is also available as an OCI artifact:

```shell
helm install hello-world oci://ghcr.io/cosmonic-labs/charts/hello-world
```

## Prerequisites for development

- `cargo` 1.82+
- [`wash`](https://wasmcloud.com/docs/installation) 0.36.1+

## Building

```bash
wash build
```

## Developing with `wash`

```shell
wash dev
```

```shell
curl http://127.0.0.1:8000
```