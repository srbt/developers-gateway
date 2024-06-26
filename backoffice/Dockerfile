FROM nginxinc/nginx-unprivileged:stable-alpine

ARG UID=101

USER root

RUN \
  rm -rf /etc/nginx \
  && mkdir /etc/nginx

COPY nginx.conf /etc/nginx/nginx.conf

USER $UID
