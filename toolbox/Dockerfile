FROM debian:bookworm-slim

COPY createCa.sh /usr/local/bin/createCa.sh

RUN apt update \
    && apt install -y --no-install-recommends \
        curl \
        openssl \
    && chmod +x /usr/local/bin/createCa.sh \
    && apt clean
