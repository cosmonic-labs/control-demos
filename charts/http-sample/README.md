# HTTP Sample Helm Chart

This is a reusable Helm chart for deploying HTTP components in Cosmonic Control.

## Usage

Deploy any of the HTTP components using this single chart with different values files:

### HTTP Server

```bash
helm install http-server ./charts/http-sample -f ../../http-server/values.yaml
```

### Hono Swagger UI

```bash
helm install hono-swagger-ui ./charts/http-sample -f ../../hono-swagger-ui/values.yaml
```

### Welcome Tour

```bash
helm install welcome-tour ./charts/http-sample -f ../../welcome-tour/values.yaml
```

## Configuration

The chart supports the following key configuration options:

- `component.name`: Name of the component
- `component.image`: Container image for the component
- `component.hostname`: Hostname for the component
- `component.config`: Key-value pairs for component-specific configuration
- `httpProvider.hostgroup`: HTTP provider hostgroup
- `httpProvider.namespace`: Namespace where HTTP provider is deployed

## Custom Values Files

Each HTTP sample contains its own `values.yaml` file in its respective directory:

- `../../http-server/values.yaml`: Configuration for the HTTP server sample
- `../../hono-swagger-ui/values.yaml`: Configuration for the Hono Swagger UI sample  
- `../../welcome-tour/values.yaml`: Configuration for the welcome tour sample
