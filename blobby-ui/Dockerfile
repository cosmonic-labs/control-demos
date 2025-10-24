FROM nginx:alpine

# Copy the HTML file to nginx
COPY src/index.html /usr/share/nginx/html/index.html

# Create nginx config with API proxy
RUN echo 'server { \
    listen 80; \
    \
    # Serve the UI \
    location / { \
        root /usr/share/nginx/html; \
        index index.html; \
        try_files $uri $uri/ /index.html; \
        \
        # Add CORS headers for the UI \
        add_header Access-Control-Allow-Origin *; \
        add_header Access-Control-Allow-Methods "GET, POST, DELETE, OPTIONS"; \
        add_header Access-Control-Allow-Headers "Content-Type"; \
    } \
    \
    # Proxy API requests to blobby service via ingress \
    location /api/ { \
        # Remove /api prefix when proxying \
        rewrite ^/api/(.*)$ /$1 break; \
        \
        proxy_pass http://ingress.cosmonic-system.svc.cluster.local:80; \
        proxy_http_version 1.1; \
        proxy_set_header Host blobby.localhost.cosmonic.sh; \
        proxy_set_header X-Real-IP $remote_addr; \
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; \
        proxy_set_header X-Forwarded-Proto $scheme; \
        proxy_set_header Upgrade $http_upgrade; \
        proxy_set_header Connection "upgrade"; \
        \
        # Add CORS headers \
        add_header Access-Control-Allow-Origin * always; \
        add_header Access-Control-Allow-Methods "GET, POST, DELETE, OPTIONS" always; \
        add_header Access-Control-Allow-Headers "Content-Type" always; \
        \
        # Handle preflight requests \
        if ($request_method = OPTIONS) { \
            add_header Access-Control-Allow-Origin * always; \
            add_header Access-Control-Allow-Methods "GET, POST, DELETE, OPTIONS" always; \
            add_header Access-Control-Allow-Headers "Content-Type" always; \
            add_header Content-Length 0; \
            return 204; \
        } \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80
