#FROM haproxy:lts
FROM debian:bookworm

RUN set -x \
    && apt update \
    && apt install -y squid \
    && mkdir /var/local/squid \
    && chown -R proxy:proxy /var/spool/squid /var/local/squid

COPY squid.conf /etc/squid/squid.conf

USER proxy

ENTRYPOINT ["squid", "-d", "9", "-N"]
