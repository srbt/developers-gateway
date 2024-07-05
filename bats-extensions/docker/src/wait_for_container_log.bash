wait_for_container_log() {
  local container="$1"
  local needle="$2"
  local retry="${3:-"20"}"
  printf 'Waiting for "%s" in "%s" ' "${needle}" "${container}"
  while ! docker logs "${container}" 2>&1 | grep -q "${needle}"; do
    retry=$(( retry - 1))
    if [[ "${retry}" == '0' ]]; then
      printf ' failed.\n'
      batslib_print_kv_single_or_multi 8 \
        'expected' "${needle}" \
        'actual' "$(docker logs "${container}" 2>&1)" \
      | batslib_decorate 'output differs' \
      | fail
      return $?
    fi
    sleep 1
    printf '.'
  done
  printf ' done.\n'
}
