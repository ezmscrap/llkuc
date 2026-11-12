#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repository_root"

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required. Install it from https://brew.sh/ first." >&2
  exit 1
fi

brew bundle --file="$repository_root/Brewfile"

tlmgr_command="${TLMGR:-/Library/TeX/texbin/tlmgr}"
if [[ ! -x "$tlmgr_command" ]]; then
  echo "BasicTeX was installed but tlmgr was not found at $tlmgr_command." >&2
  exit 1
fi

tlmgr_arguments=(install
  luatex
  collection-langjapanese
  collection-fontsrecommended
  fontspec
  lualatex-math
  luatexja
  selnolig
  xurl
  fancyhdr
  titlesec
  xcolor
)

# Homebrew runs as the current user, while BasicTeX installed in /usr/local
# needs administrator authority only when its TeX Live package tree changes.
if command -v sudo >/dev/null 2>&1; then
  sudo "$tlmgr_command" "${tlmgr_arguments[@]}"
else
  "$tlmgr_command" "${tlmgr_arguments[@]}"
fi

echo "PDF build tools are ready. Run scripts/build-pdf.sh."
