#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "$0")/.." && pwd)"
pdf_file="${1:-$repository_root/output/pdf/llkuc-rulebook.pdf}"
preview_directory="$repository_root/tmp/pdfs/llkuc-rulebook"

if [[ ! -f "$pdf_file" ]]; then
  echo "PDF not found: $pdf_file" >&2
  exit 1
fi
if ! command -v pdftoppm >/dev/null 2>&1; then
  echo "pdftoppm is required. Run scripts/bootstrap-pdf-tools.sh first." >&2
  exit 1
fi

mkdir -p "$preview_directory"
pdftoppm -png -r 150 "$pdf_file" "$preview_directory/page"
echo "Rendered page previews to $preview_directory"
