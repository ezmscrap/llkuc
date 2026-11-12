#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "$0")/.." && pwd)"
book_root="$repository_root/from0079-to0093"
output_directory="$repository_root/output/pdf"
output_file="$output_directory/llkuc-rulebook.pdf"

# BasicTeX may be installed system-wide, where luaotfload cannot write its
# cache as an ordinary user. Keep that cache inside this working copy.
export TEXMFVAR="$repository_root/.cache/texmf-var"
mkdir -p "$TEXMFVAR"

# BasicTeX on macOS installs TeX Live here; do not require users to modify
# their shell startup files merely to build this book.
if [[ -d /Library/TeX/texbin ]]; then
  export PATH="/Library/TeX/texbin:$PATH"
fi

for command in pandoc lualatex; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "$command is required. Run scripts/bootstrap-pdf-tools.sh first." >&2
    exit 1
  fi
done

# Pandoc sanitizes PATH before launching the PDF engine on some macOS
# installations.  Use the absolute TeX Live path when it is present.
pdf_engine="lualatex"
if [[ -x /Library/TeX/texbin/lualatex ]]; then
  pdf_engine="/Library/TeX/texbin/lualatex"
fi

for tex_file in luatexja.sty luatexja-fontspec.sty; do
  if ! kpsewhich "$tex_file" >/dev/null 2>&1; then
    echo "$tex_file is missing. Run scripts/bootstrap-pdf-tools.sh to install the Japanese TeX packages." >&2
    exit 1
  fi
done

mkdir -p "$output_directory"
chapter_files=()
while IFS= read -r chapter || [[ -n "$chapter" ]]; do
  [[ -z "$chapter" ]] && continue
  chapter_files+=("$chapter")
done < "$book_root/book-order.txt"

for chapter in "${chapter_files[@]}"; do
  if [[ ! -f "$book_root/$chapter" ]]; then
    echo "Missing chapter listed in book-order.txt: $chapter" >&2
    exit 1
  fi
done

# Pandoc resolves image links relative to the process directory rather than
# consistently relative to every source Markdown file. Include every chapter
# directory so both ../assets and ../../assets links resolve without changing
# the editing source.
resource_paths=("$book_root" "$repository_root")
while IFS= read -r directory; do
  resource_paths+=("$directory")
done < <(find "$book_root/chapters" -type d -print | sort)
resource_path="$(IFS=:; printf '%s' "${resource_paths[*]}")"

cd "$book_root"
pandoc \
  --from=markdown \
  --metadata-file=book.yaml \
  --resource-path="$resource_path" \
  --toc \
  --number-sections \
  --top-level-division=chapter \
  --pdf-engine="$pdf_engine" \
  --include-in-header=styles/rulebook.tex \
  --output="$output_file" \
  "${chapter_files[@]}"

echo "Created $output_file"
