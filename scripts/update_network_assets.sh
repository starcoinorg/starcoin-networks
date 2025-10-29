#!/usr/bin/env bash
# shellcheck disable=SC2086
#
# Regenerate the Move stdlib artefacts and genesis blobs by leveraging the
# official starcoin workspace. The refreshed files are written into this repo.
#
# Environment variables:
#   STARCOIN_REPO_URL   Optional git URL used to clone the starcoin source.
#                       Defaults to https://github.com/starcoinorg/starcoin.git
#   STARCOIN_REPO_REF   Optional git ref (branch, tag, or commit). Defaults to dual-verse-dag.
#   CARGO_TOOLCHAIN     Rust toolchain passed to cargo (defaults to nightly).
#   STDLIB_ARGS         Extra arguments appended after `cargo run -p stdlib`.
#   GENESIS_ARGS        Extra arguments appended after `cargo run -p starcoin-genesis`.
#
# Example:
#   CARGO_TOOLCHAIN=nightly ./scripts/update_network_assets.sh

set -euo pipefail

REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
STARCOIN_REPO_URL="${STARCOIN_REPO_URL:-https://github.com/starcoinorg/starcoin.git}"
STARCOIN_REPO_REF="${STARCOIN_REPO_REF:-dual-verse-dag}"
CARGO_TOOLCHAIN="${CARGO_TOOLCHAIN:-nightly}"
STDLIB_ARGS=${STDLIB_ARGS:-}
GENESIS_ARGS=${GENESIS_ARGS:-}

tmpdir="$(mktemp -d -t starcoin-src-XXXXXX)"
cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT

echo "Cloning starcoin (${STARCOIN_REPO_REF}) from ${STARCOIN_REPO_URL}..."
git clone --depth 1 --branch "$STARCOIN_REPO_REF" "$STARCOIN_REPO_URL" "$tmpdir/starcoin" >/dev/null
STARCOIN_DIR="$tmpdir/starcoin"

if [[ -e "$STARCOIN_DIR/networks" ]]; then
    rm -rf "$STARCOIN_DIR/networks"
fi
ln -s "$REPO_ROOT" "$STARCOIN_DIR/networks"

pushd "$STARCOIN_DIR" >/dev/null

cargo_flags=()
if [[ -f "$STARCOIN_DIR/cargo-flags" ]]; then
  if read -r flags < "$STARCOIN_DIR/cargo-flags"; then
    if [[ -n "${flags:-}" ]]; then
      # shellcheck disable=SC2206 # intentional splitting on whitespace
      cargo_flags=(${flags})
    fi
  fi
fi

run_cargo() {
  local package="$1"
  shift || true
  local extra_args=("$@")

  local args=()
  if [[ -n "${CARGO_TOOLCHAIN:-}" ]]; then
    args+=("+${CARGO_TOOLCHAIN}")
  fi
  args+=("run")
  if [[ ${#cargo_flags[@]} -gt 0 ]]; then
    args+=("${cargo_flags[@]}")
  fi
  args+=("--release" "-p" "$package")
  if [[ ${#extra_args[@]} -gt 0 ]]; then
    args+=("--")
    args+=("${extra_args[@]}")
  fi

  echo "Executing: cargo ${args[*]}"
  cargo "${args[@]}"
}

run_cargo "stdlib" ${STDLIB_ARGS}
run_cargo "starcoin-genesis" ${GENESIS_ARGS}

popd >/dev/null

echo "Regeneration complete. Updated files are now in ${REPO_ROOT}/stdlib and ${REPO_ROOT}/genesis."
