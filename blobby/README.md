# Blobstore File Server for Cosmonic Control

This is an HTTP-based blob file server (affectionately nicknamed "blobby") written in Rust, implemented as a Wasm component and packaged for deployment to Kubernetes clusters with [Cosmonic Control](https://cosmonic.com/docs/). 

When deployed on Cosmonic Control with the manifests or Helm chart in this repository, it is backed by NATS file storage.

## Deploy with Cosmonic Control

Deploy this template to a Kubernetes cluster with Cosmonic Control using the included Helm chart:

```shell
helm install blobby-nats ./chart/blobby
```

## Test the component

```shell
echo 'Hello there!' > myfile.txt
```
```shell
curl -H 'Content-Type: text/plain' -v 'http://localhost:9091/myfile.txt' --data-binary @myfile.txt
```