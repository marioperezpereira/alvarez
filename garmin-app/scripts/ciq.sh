#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_DEVICE="fr970"
KEY_PATH="${CIQ_DEV_KEY:-$HOME/.garmin-keys/developer_key.der}"

resolve_sdk_bin() {
    if [[ -n "${CIQ_SDK_BIN:-}" ]]; then
        echo "$CIQ_SDK_BIN"
        return
    fi

    local sdk_root="${CIQ_SDK_ROOT:-$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks}"
    local latest_sdk
    latest_sdk="$(ls -dt "$sdk_root"/connectiq-sdk-mac-* 2>/dev/null | head -n 1 || true)"
    if [[ -z "$latest_sdk" ]]; then
        echo "Unable to find Connect IQ SDK under: $sdk_root" >&2
        echo "Set CIQ_SDK_BIN or CIQ_SDK_ROOT and retry." >&2
        exit 1
    fi
    echo "$latest_sdk/bin"
}

java_opts_with_headless() {
    local existing="${JAVA_TOOL_OPTIONS:-}"
    echo "${existing} -Djava.awt.headless=true"
}

build_prg() {
    local device="$1"
    local sdk_bin="$2"
    local monkeyc="$sdk_bin/monkeyc"
    local output="$ROOT_DIR/build/alvarez-diper-${device}.prg"

    if [[ ! -f "$KEY_PATH" ]]; then
        echo "Developer key not found at: $KEY_PATH" >&2
        echo "Set CIQ_DEV_KEY to your .der key and retry." >&2
        exit 1
    fi

    JAVA_TOOL_OPTIONS="$(java_opts_with_headless)" \
        "$monkeyc" \
        -f "$ROOT_DIR/monkey.jungle" \
        -o "$output" \
        -d "$device" \
        -w \
        -y "$KEY_PATH"

    echo "$output"
}

run_simulator() {
    local device="$1"
    local sdk_bin="$2"
    local prg="$3"

    if [[ ! -f "$prg" ]]; then
        echo "PRG not found: $prg" >&2
        exit 1
    fi

    if [[ "$(uname)" == "Darwin" ]]; then
        open "$sdk_bin/ConnectIQ.app"
        sleep 2
    fi

    JAVA_TOOL_OPTIONS="$(java_opts_with_headless)" \
        "$sdk_bin/monkeydo" "$prg" "$device"
}

usage() {
    cat <<EOF
Usage:
  $(basename "$0") build [device]
  $(basename "$0") run [device]
  $(basename "$0") all [device]

Defaults:
  device: ${DEFAULT_DEVICE}

Environment:
  CIQ_SDK_BIN   Connect IQ SDK bin directory override
  CIQ_SDK_ROOT  Connect IQ SDK root directory (default: ~/Library/Application Support/Garmin/ConnectIQ/Sdks)
  CIQ_DEV_KEY   Garmin developer key path (default: ~/.garmin-keys/developer_key.der)
EOF
}

main() {
    local cmd="${1:-}"
    local device="${2:-$DEFAULT_DEVICE}"

    if [[ -z "$cmd" ]]; then
        usage
        exit 1
    fi

    local sdk_bin
    sdk_bin="$(resolve_sdk_bin)"
    local prg_path="$ROOT_DIR/build/alvarez-diper-${device}.prg"

    case "$cmd" in
        build)
            build_prg "$device" "$sdk_bin" >/dev/null
            echo "Built: $prg_path"
            ;;
        run)
            run_simulator "$device" "$sdk_bin" "$prg_path"
            ;;
        all)
            build_prg "$device" "$sdk_bin" >/dev/null
            echo "Built: $prg_path"
            run_simulator "$device" "$sdk_bin" "$prg_path"
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

main "$@"
