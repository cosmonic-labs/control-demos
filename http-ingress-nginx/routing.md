---
title: "Host-based routing"
---

## Create an Ingress-ready kind cluster

Create kind cluster:

```shell
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF
```

Add NGINX Ingress:

```shell
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
```

Wait until it's ready:

```shell
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

## Install Cosmonic Control with HostGroup

```shell
helm install cosmonic-control oci://ghcr.io/cosmonic/cosmonic-control\
  --version 0.2.0\
  --namespace cosmonic-system\
  --create-namespace\
  --set cosmonicLicenseKey="<insert license here>"
```

Wait until it's ready:

```shell
kubectl wait --namespace cosmonic-system \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=cosmonic-control
```

Install a HostGroup:

```shell
helm install hostgroup oci://ghcr.io/cosmonic/cosmonic-control-hostgroup --version 0.2.0 --namespace cosmonic-system --set http.enabled=true
```

Wait until it's ready:

```shell
kubectl wait --namespace cosmonic-system \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/instance=hostgroup \
  --timeout=120s
```

## Deploy MCP Component

```shell
helm install weather-gov-mcp oci://ghcr.io/cosmonic-labs/charts/http-sample \
  -n weather-gov --create-namespace \
  --set component.image=ghcr.io/cosmonic-labs/components/weather-gov-mcp:0.1.0 \
  --set component.name=weather-gov-mcp
```

## Deploy Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: mcp-weather-ingress
  namespace: cosmonic-system
spec:
  ingressClassName: nginx
  rules:
    - host: localhost
      http:
        paths:
          - path: /weather
            pathType: Prefix
            backend:
              service:
                name: hostgroup-default
                port:
                  number: 9091
```
```shell
kubectl apply -f ingress.yaml
```
