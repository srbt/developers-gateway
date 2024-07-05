#!/usr/bin/env bash

set -e

function createCa() {
  local pathToCa="$1"

  mkdir -p "${pathToCa}"
  openssl genrsa -des3 -out "${pathToCa}/myCA.key" -passout pass:client11 2048
  openssl req -x509 -new -nodes -key "${pathToCa}/myCA.key" \
    -passin pass:client11 -sha256 -days 1825 -out "${pathToCa}/myCA.pem" \
    -subj "/C=CZ/ST=Czech Republic/L=Prague/O=ACME/OU=IT/CN=Tests/emailAddress=tomas.srb@example.com"
}

function createCert() {
  local pathToCa="$1"
  local siteName="$2"
  local networkAddress="$3"
  local siteExt="
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${siteName}
DNS.2 = *.${siteName}
"
  if [[ -n "${networkAddress}" ]]; then
    for suffix in {1..15}; do
      siteExt="${siteExt}IP.${suffix} = ${networkAddress}.${suffix}"$'\n'
    done
  fi
  printf 'siteExt: %s\n' "${siteExt}"
  openssl genrsa -out "${pathToCa}/site.test.key" 2048
  openssl req -new -key "${pathToCa}/site.test.key" -out "${pathToCa}/site.test.csr" \
    -subj "/C=CZ/ST=Czech Republic/L=Prague/O=ACME/OU=IT/CN=TestsSite/emailAddress=tomas.srb@example.com"
  openssl x509 -req -in "${pathToCa}/site.test.csr" -CA "${pathToCa}/myCA.pem" -CAkey "${pathToCa}/myCA.key" \
    -passin pass:client11 \
    -CAcreateserial -out "${pathToCa}/site.test.crt" -days 825 -sha256 \
    -extfile <(printf '%s\n' "${siteExt}")
}
createCa '/certs'
createCert '/certs' 'in.application.com' ''
cat /certs/site.test.crt /certs/site.test.key /certs/myCA.pem > /certs/bundle.pem

