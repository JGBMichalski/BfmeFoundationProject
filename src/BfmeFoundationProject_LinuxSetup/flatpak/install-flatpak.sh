#!/usr/bin/env bash
# Installs the BFME Foundation Project Flatpak together with the 32-bit Flatpak extensions it needs.
# Flatpak does not install those extensions for apps that are not on Flathub, so this does it for you.
# Runs as your user. No sudo.
#
# Usage: install-flatpak.sh [--repo URL_OR_PATH | --bundle FILE.flatpak]
#   --repo URL    Flatpak repository to install from (default: the project's repository)
#   --bundle FILE Install from a single .flatpak file instead

set -euo pipefail

readonly APP_ID="BfmeFoundationProject.AllInOneLauncher.Linux"
readonly RUNTIME_VERSION="25.08"
readonly REMOTE_NAME="bfme-foundation"
# CI replaces the placeholder with the published repository address in the copy it publishes.
readonly DEFAULT_REPO="@BFME_DEFAULT_REPO@"
REPO="${BFME_FLATPAK_REPO:-}"
BUNDLE=""

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
say() { printf '%s\n' "$*"; }

while [ $# -gt 0 ]; do
  case "$1" in
    --repo)   REPO="${2:-}"; shift 2 ;;
    --bundle) BUNDLE="${2:-}"; shift 2 ;;
    -h|--help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "Unknown option '$1'. Run with --help." ;;
  esac
done

if [ -z "$REPO" ] && [ -z "$BUNDLE" ]; then
  case "$DEFAULT_REPO" in
    "@"*) ;;                       # still the placeholder: no default repository
    *)    REPO="$DEFAULT_REPO" ;;
  esac
fi

command -v flatpak >/dev/null 2>&1 || die "Flatpak is not installed. Install it first: https://flatpak.org/setup/"
[ -n "$REPO" ] || [ -n "$BUNDLE" ] || die "Give --repo URL or --bundle FILE (or set BFME_FLATPAK_REPO)."
[ -z "$BUNDLE" ] || [ -f "$BUNDLE" ] || die "Bundle '$BUNDLE' was not found."

say "Step 1: make sure Flathub is available for the runtime and the 32-bit extensions"
if ! flatpak remotes --columns=name | grep -qx flathub; then
  flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
fi

say "Step 2: install the 32-bit extensions"
ext=("org.freedesktop.Platform.Compat.i386//${RUNTIME_VERSION}" "org.freedesktop.Platform.GL32.default//${RUNTIME_VERSION}")

# NVIDIA: the 32-bit driver must match the 64-bit one Flatpak already installed for your card.
nvidia="$(flatpak list --runtime --columns=application,branch 2>/dev/null \
  | awk '$1 ~ /^org\.freedesktop\.Platform\.GL\.nvidia-/ {print $1 "//" $2}' | sort -u || true)"
if [ -n "$nvidia" ]; then
  while IFS= read -r line; do
    ext+=("${line/Platform.GL.nvidia/Platform.GL32.nvidia}")
  done <<<"$nvidia"
fi

flatpak install --user -y --noninteractive flathub "${ext[@]}"

say "Step 3: install the app"
if [ -n "$BUNDLE" ]; then
  flatpak install --user -y --noninteractive --bundle "$BUNDLE"
else
  case "$REPO" in
    /*) REPO="file://$REPO" ;;
  esac
  flatpak remote-add --user --if-not-exists --no-gpg-verify "$REMOTE_NAME" "$REPO"
  flatpak install --user -y --noninteractive "$REMOTE_NAME" "$APP_ID"
fi

say ""
say "Done. Open 'BFME All-in-One Launcher' or 'BFME Online Arena' from your application menu."
say "The first start downloads Proton and sets up the environment, which takes a few minutes."
