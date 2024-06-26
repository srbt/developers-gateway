#!/usr/bin/env bats

load bats-helpers/bats-support/load
load bats-helpers/bats-assert/load
load bats-extensions/docker/load

setup() {
  export TEST_CONTEXT="${USER}_$$_${RANDOM}"
  export TEST_NETWORK="${TEST_CONTEXT}"
  export IMAGE_BACKOFFICE="${TEST_CONTEXT}_backoffice"
  export CON_BACKOFFICE="${TEST_CONTEXT}_backoffice"
  export IMAGE_TOOLBOX="${TEST_CONTEXT}_toolbox"
  export IMAGE_FORWARD_PROXY="${TEST_CONTEXT}_forward_proxy"
  export CON_FORWARD_PROXY="${TEST_CONTEXT}_forward_proxy"
  export IMAGE_REVERSE_PROXY="${TEST_CONTEXT}_reverse_proxy"
  export CON_REVERSE_PROXY="${TEST_CONTEXT}_reverse_proxy"

  mkdir "${TEST_CONTEXT}"
  docker network create "${TEST_NETWORK}"
  docker build -t "${IMAGE_BACKOFFICE}" backoffice
  docker build -t "${IMAGE_TOOLBOX}" toolbox
  docker build -t "${IMAGE_FORWARD_PROXY}" forward-proxy
  docker build -t "${IMAGE_REVERSE_PROXY}" reverse-proxy
  mkdir "${TEST_CONTEXT}/certs"
  docker run --rm -u "$(id -u):$(id -g)" -v "${PWD}/${TEST_CONTEXT}/certs:/certs" "${IMAGE_TOOLBOX}" /usr/local/bin/createCa.sh
  docker run -d --network "${TEST_NETWORK}" --hostname "backoffice.in.application.com" --name "${CON_BACKOFFICE}" "${IMAGE_BACKOFFICE}"
  docker run -d --network "${TEST_NETWORK}" --hostname "reverse-proxy.in.application.com" --name "${CON_REVERSE_PROXY}" -v "${PWD}/${TEST_CONTEXT}/certs:/certs" "${IMAGE_REVERSE_PROXY}"
  docker run -d --network "${TEST_NETWORK}" --hostname "forward-proxy.in.application.com" --name "${CON_FORWARD_PROXY}" -v "${PWD}/${TEST_CONTEXT}/certs:/certs" -p 3128:3128 "${IMAGE_FORWARD_PROXY}"
}

@test "Backoffice container is running" {
  run docker ps
  assert_success
  assert_output --partial "${CON_BACKOFFICE}"
  run docker run --rm --network "${TEST_NETWORK}" "${IMAGE_TOOLBOX}" curl -s -o /dev/null -w "%{http_code}" "http://backoffice.in.application.com:8080/status"
  assert_success
  assert_output '200'
}

@test "Reverse proxy is working" {
  run docker ps
  assert_success
  assert_output --partial "${CON_REVERSE_PROXY}"
  run docker run --rm --network "${TEST_NETWORK}" -v "${PWD}/${TEST_CONTEXT}/certs:/certs" "${IMAGE_TOOLBOX}" curl -s -o /dev/null -w "%{http_code}" --connect-to 'backoffice.in.application.com:443:reverse-proxy.in.application.com:443' -v --cacert /certs/myCA.pem "https://backoffice.in.application.com/status"
  assert_success
  assert_output --partial 'SSL certificate verify ok.'
  assert_output --partial "HTTP/1.1 200 OK"
  run docker logs "${CON_REVERSE_PROXY}"
  assert_output --partial "GET /status HTTP/1.1"
  run docker logs "${CON_BACKOFFICE}"
  assert_output --partial "GET /status HTTP/1.0"
}

@test "Forward proxy and reverse proxy is working" {
  wait_for_container_log "${CON_FORWARD_PROXY}" "Accepting HTTP Socket connections"
#  wait_for_container_log "${CON_FORWARD_PROXY}" "Accepting SSL bumped HTTP Socket connections"
  run docker ps
  assert_success
  assert_output --partial "${CON_FORWARD_PROXY}"
  run docker run --rm -e "https_proxy=http://${HOSTNAME}:3128" -v "${PWD}/${TEST_CONTEXT}/certs:/certs" "${IMAGE_TOOLBOX}" curl -s -o /dev/null -v --cacert /certs/myCA.pem "https://backoffice.in.application.com/status"
  assert_success
  assert_output --partial 'SSL certificate verify ok.'
  assert_output --partial "HTTP/1.1 200 OK"
  run docker logs "${CON_REVERSE_PROXY}"
  assert_output --partial "GET /status HTTP/1.1"
  run docker logs "${CON_BACKOFFICE}"
  assert_output --partial "GET /status HTTP/1.0"
}

teardown() {
  printf '============ TEARDOWN ============\n'
  docker ps
  printf '============ FORWARD PROXY LOGS ============\n'
  docker logs "${CON_FORWARD_PROXY}"
  printf '============ REVERSE PROXY LOGS ============\n'
  docker logs "${CON_REVERSE_PROXY}"
  printf '============ BACKOFFICE LOGS ============\n'
  docker logs "${CON_BACKOFFICE}"
  docker rm -f "${CON_BACKOFFICE}" "${CON_FORWARD_PROXY}" "${CON_REVERSE_PROXY}"
  docker network rm "${TEST_NETWORK}"
  docker rmi "${IMAGE_BACKOFFICE}" "${IMAGE_TOOLBOX}" "${IMAGE_FORWARD_PROXY}" "${IMAGE_REVERSE_PROXY}"
  rm -rf "${TEST_CONTEXT}"
}
