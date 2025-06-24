# Cosmonic Control - "Blobby" Helm chart

This is a Helm chart for installing the Cosmonic Control "Blobby" example. Blobby is a blobstore file-server that can be backed with any S3-compatible service. 

## Quickstart

From `charts/blobby`:

```shell
helm install -f values.yaml blobby ./
```

## Manifests

The example is comprised of manifests for the following resources:

- [Component](https://cosmonic.com/docs/custom-resources/#component)
- [Provider](https://cosmonic.com/docs/custom-resources/#provider)
- [Config](https://cosmonic.com/docs/custom-resources/#config)

You can learn more about these resources at [https://cosmonic.com/docs/custom-resources/](https://cosmonic.com/docs/custom-resources/).