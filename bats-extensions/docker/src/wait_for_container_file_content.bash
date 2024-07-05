wait_for_container_file_content() {
  local container="$1"
  local file="$2"
  local needle="$3"
  local retry=20
  printf 'Waiting for "%s" in "%s:%s" ' "${needle}" "${container}" "${file}"
  while ! docker exec "${container}" grep -q "${needle}" "${file}"; do
    retry=$(( retry - 1))
    if [[ "${retry}" == '0' ]]; then
      printf ' failed.\n'
      batslib_print_kv_single_or_multi 8 \
        'expected' "${needle}" \
        'actual' "$(docker exec "${container}" cat "${file}" 2>&1)" \
      | batslib_decorate 'output differs' \
      | fail
      return $?
    fi
    sleep 1
    printf '.'
  done
  printf ' done.\n'
}
