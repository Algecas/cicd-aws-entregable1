FROM nginx:alpine
COPY index.html /usr/share/nginx/html/
COPY nginx.conf.template /etc/nginx/templates/default.conf.template
ENV BACKEND_HOST=backend \
    BACKEND_PORT=5000 \
    NGINX_ENVSUBST_FILTER='^(BACKEND_HOST|BACKEND_PORT)$'
EXPOSE 80
