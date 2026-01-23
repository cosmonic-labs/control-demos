# Blobby UI - Web Interface for Blobstore

This UI provides a user-friendly way to interact with the [Blobby component](../blobby/README.md) for uploading, downloading, and managing files in blob storage.

## Overview

The Blobby UI is a single-page application built with vanilla HTML, CSS, and JavaScript. In production environments, **this would typically be served by a CDN** for optimal performance and global distribution. For demonstration purposes, we provide a containerized nginx deployment that also handles API proxying to avoid CORS issues.

## Architecture

The UI consists of:

- **Static HTML/CSS/JavaScript**: Single `index.html` file with embedded styles and scripts
- **Nginx Container**: Serves the static UI and proxies API requests to the Blobby backend
- **No Dependencies**: Pure vanilla JavaScript, no build process required

The nginx container approach shown here is for demo/development purposes only.

## Features

- **File Upload**: Upload single or multiple files simultaneously
- **File Download**: Download stored files with a single click
- **File Management**: View all uploaded files with visual file type indicators
- **File Deletion**: Remove files from storage with confirmation
- **Responsive Design**: Modern UI with gradient backgrounds and smooth animations
- **Client-Side Tracking**: Uses browser localStorage to remember uploaded files

## Prerequisites

- Kubernetes cluster (local kind cluster recommended)
- Cosmonic Control installed (see [Blobby README](../blobby/README.md))
- Blobby component deployed and accessible

## Quick Start

### 1. Set up local Kubernetes with Cosmonic Control

Follow the setup instructions in the [Blobby README](../blobby/README.md) to:

1. Install kind with the proper configuration
2. Deploy Cosmonic Control
3. Deploy the Blobby component

### 2. Deploy Blobby UI

From the `blobby-ui` directory:

```bash
# Build the Docker image
docker build -t ghcr.io/ricochet/blobby-ui:latest .

# Load the image into kind
kind load docker-image ghcr.io/ricochet/blobby-ui:latest

# Create the namespace
kubectl create namespace blobby-ui

# Deploy the UI
kubectl apply -f deployment.yaml
```

### 3. Access the UI

Port-forward to access the UI locally:

```bash
kubectl port-forward -n blobby-ui svc/blobby-ui 8888:80
```

Open your browser to: http://localhost:8888

### 4. Use the UI

1. Click "Choose File" or drag files to upload
2. Click "Upload Files" to store them in Blobby
3. View your uploaded files in the "Stored Files" section
4. Download or delete files as needed

## Running the Demo

### Complete Demo Walkthrough

```bash
# 1. Ensure Blobby is running
helm list -n blobby
# You should see the blobby release

# 2. Build and deploy blobby-ui
cd blobby-ui
docker build -t ghcr.io/ricochet/blobby-ui:latest .
kind load docker-image ghcr.io/ricochet/blobby-ui:latest
kubectl create namespace blobby-ui --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f deployment.yaml

# 3. Wait for pod to be ready
kubectl wait --for=condition=ready pod -l app=blobby-ui -n blobby-ui --timeout=60s

# 4. Start port-forward in a separate terminal
kubectl port-forward -n blobby-ui svc/blobby-ui 8888:80

# 5. Open browser to http://localhost:8888
```

### Testing with curl

You can also test the API proxy functionality directly:

```bash
# Upload a test file
echo "Hello from Blobby!" > test.txt
kubectl exec -n blobby-ui deployment/blobby-ui -- sh -c \
  'echo "test content" | curl -s -X POST http://localhost/api/testfile.txt \
  -H "Content-Type: text/plain" --data-binary @-'

# Download the file
kubectl exec -n blobby-ui deployment/blobby-ui -- \
  curl -s http://localhost/api/testfile.txt
```

## Configuration

### API Proxy

The nginx configuration proxies `/api/` requests to the Blobby service:

- **Proxy Target**: `http://ingress.cosmonic-system.svc.cluster.local:80`
- **Host Header**: `blobby.localhost.cosmonic.sh`
- **Path Rewriting**: `/api/*` → `/*`
- **CORS**: Enabled for all origins (demo only - restrict in production)

### Dockerfile

The Dockerfile uses nginx:alpine and includes:

- Static HTML serving on port 80
- API proxy configuration for `/api/` path
- CORS headers for browser compatibility
- Minimal resource footprint (~40MB total)

## Development

## Troubleshooting

### CORS Errors

If you see CORS errors:

1. Verify the nginx proxy is working: `kubectl logs -n blobby-ui deployment/blobby-ui`
2. Check that Blobby is accessible: `kubectl get pods -n blobby`
3. Ensure port-forwarding is active

### Files Not Appearing

The UI uses browser localStorage to track files. If files don't appear:

1. Check browser console for errors (F12 → Console)
2. Clear localStorage: `localStorage.clear()` in browser console
3. Verify files were actually uploaded by checking the Blobby backend

## Resource Requirements

The blobby-ui deployment is intentionally minimal:

- **Memory**: 32Mi request, 64Mi limit
- **CPU**: 50m request, 100m limit
- **Image Size**: ~40MB (nginx:alpine + HTML file)

## Clean Up

```bash
# Delete the blobby-ui deployment
kubectl delete namespace blobby-ui

# (Optional) Remove the Docker image from kind
docker exec kind-control-plane crictl rmi ghcr.io/ricochet/blobby-ui:latest
```

## Related

- [Blobby Backend](../blobby/README.md) - The WebAssembly component this UI interfaces with
