#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"
export BIN_PATH="../../bin"

function installBats() {
  git clone https://github.com/bats-core/bats-core.git
}

function installBatsHelper() {
  git clone https://github.com/bats-core/bats-support.git bats-helpers/bats-support
  git clone https://github.com/bats-core/bats-assert.git bats-helpers/bats-assert
}

function runBats() {
  bats-core/bin/bats "$@"
}

if ! [[ -d bats-core ]]; then
  installBats
fi

if ! [[ -d bats-helpers ]]; then
  installBatsHelper
fi

runStats='n'
tests=()
params=()

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --stats)
      runStats='30'
      shift
      if [[ "$1" =~ ^[0-9]+$ ]]; then
        runStats="$1"
        shift
      fi
      ;;
    --help|-h)
      printf 'Usage: %s [--stats [count]] [bats options...] [test1.bats] [test2.bats] ...\n' "$0"
      printf '  --stats [count]      Run the tests multiple times and show the stats\n'
      printf '  --help, -h           Show this help\n'
      printf '  bats options         Options to pass to the bats:\n'
      runBats --help
      exit 0
      ;;
    *.bats)
      tests+=("$1")
      shift
      ;;
    *)
      params+=("$1")
      shift
      ;;
  esac
done
if [[ "${#tests[@]}" -eq 0 ]]; then
  tests=( *.bats )
fi

if [[ "${runStats}" != 'n' ]]; then
  errors=0
  map=''
  for counter in $(seq "${runStats}"); do
    printf 'Try no %d\n' "${counter}"
    if runBats "${params[@]}" "${tests[@]}"; then
      map+='.'
    else
      map+='!'
      errors=$(( errors + 1 ))
    fi
  done
  printf '\n%d errors in %d runs\n[%s]\n' "${errors}" "${runStats}" "$map"
else
  runBats "${params[@]}" "${tests[@]}"
fi
