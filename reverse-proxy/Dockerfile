FROM nginxinc/nginx-unprivileged:stable-alpine

ARG UID=101
ARG NODES_PROTOCOL

USER root

RUN \
  rm -rf /etc/nginx \
  && mkdir /etc/nginx /etc/nginx/conf.d /etc/nginx/templates \
  && chown -R $UID /etc/nginx/conf.d

COPY nginx.${NODES_PROTOCOL}.conf /etc/nginx/nginx.conf
COPY resolvers.conf.template /etc/nginx/templates/resolvers.conf.template

ENV NGINX_ENTRYPOINT_LOCAL_RESOLVERS=yes

#USER $UID
