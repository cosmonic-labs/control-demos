# HTTP Trigger Helm Chart

This is a reusable Helm chart for deploying HTTP components with automatic ingress in Cosmonic Control. The chart renders a `WorkloadDeployment` that runs the component and a `control.cosmonic.io/v1alpha2` [HTTPTrigger](https://cosmonic.com/docs/custom-resources#httptrigger) that routes the ingress host and paths to it. Chart `0.2.0` and later require Cosmonic Control v0.13.0 or later; use chart `0.1.x` with earlier Control releases.

## Usage

Deploy any of the HTTP components using this single chart with different values files:

### HTTP Server

```bash
helm install http-server ./charts/http-trigger -f ../../http-server/values.http-trigger.yaml
```

### Hono Swagger UI

```bash
helm install hono-swagger-ui ./charts/http-trigger -f ../../hono-swagger-ui/values.http-trigger.yaml
```

### Welcome Tour

```bash
helm install welcome-tour ./charts/http-trigger -f ../../welcome-tour/values.http-trigger.yaml
```

## Configuration

The chart supports the following key configuration options:

- `component.name`: Name of the component
- `component.image`: Container image for the component
- `replicas`: How many copies of the components above to schedule (default: `1`)
- `ingress.host`: Hostname used for ingress
- `ingress.paths.path`: Multiple workloads can bind to the same "host" under different paths. (default: `/`)
- `ingress.paths.pathType`: Multiple workloads can bind to the same "host" under different paths. (default: `Prefix`)

### Configuration with additional host interfaces

You can use the `hostInterfaces` field to deploy a component that uses other available host interfaces in addition to HTTP. `hostInterfaces` requires the following subfields:

* `namespace`
* `package`
* `version`
* `interfaces`

Below is an example adding the blobstore interface for the [Blobby](../../blobby/) demo:

```yaml
# For the 'http-trigger' helm chart
components:
  - name: blobby
    image: ghcr.io/cosmonic-labs/components/blobby:0.2.0

ingress:
  host: "blobby.localhost.cosmonic.sh"

hostInterfaces:
  - namespace: wasi
    package: blobstore
    version: 0.2.0-draft
    interfaces:
      - blobstore
  - namespace: wasi
    package: logging
    version: 0.1.0-draft
    interfaces:
      - logging
```

## Custom Values Files

Each HTTP sample contains its own `values.http-trigger.yaml` file in its respective directory:

- `../../http-server/values.http-trigger.yaml`: Configuration for the HTTP server sample
- `../../hono-swagger-ui/values.http-trigger.yaml`: Configuration for the Hono Swagger UI sample  
- `../../welcome-tour/values.http-trigger.yaml`: Configuration for the Welcome Tour sample
