#!/usr/bin/env bash
# Extract the Word VML figures as display-ready PNG files.
#
# The VML fragments in assets/shapes are retained as the editable source, but
# neither Pandoc nor LuaLaTeX can render Word's VML.  The original PDF is the
# authoritative rendering used to make these images.
set -euo pipefail

root_dir="$(cd "$(dirname "$0")/.." && pwd)"
source_pdf="$root_dir/output/20071215_From0079_To0093.pdf"
output_dir="$root_dir/from0079-to0093/assets/figures"
work_dir="$root_dir/tmp/pdfs/source-figures"

command -v pdftoppm >/dev/null || { echo 'pdftoppm (poppler) is required.' >&2; exit 1; }
command -v ffmpeg >/dev/null || { echo 'ffmpeg is required.' >&2; exit 1; }
[[ -f "$source_pdf" ]] || { echo "Original PDF not found: $source_pdf" >&2; exit 1; }

mkdir -p "$output_dir" "$work_dir"

# Values below are x:y:width:height in the 150 dpi coordinate system.  They
# are doubled for the 300 dpi source images, giving the rulebook a crisp PDF
# result while retaining a repeatable extraction procedure.
figures=(
  '001:7:720:590:410:680'
  '002:8:690:185:400:300'
  '003:8:140:1080:430:330'
  '004:8:680:525:430:410'
  '005:10:145:720:470:500'
  '006:17:115:185:470:970'
  '007:18:115:125:480:735'
  '008:18:675:395:445:345'
  '009:18:675:1110:445:365'
  '010:19:135:670:440:350'
  '011:19:675:180:445:350'
  '012:20:135:180:440:270'
  '013:20:675:640:445:380'
  '026:24:135:220:985:440'
  '027:25:135:10:985:620'
)

for figure in "${figures[@]}"; do
  IFS=: read -r number page x y width height <<<"$figure"
  source_png="$work_dir/page-${page}.png"
  if [[ ! -f "$source_png" ]]; then
    pdftoppm -f "$page" -l "$page" -r 300 -png -singlefile "$source_pdf" "$work_dir/page-${page}"
  fi
  ffmpeg -hide_banner -loglevel error -y -i "$source_png" \
    -vf "crop=$((width * 2)):$((height * 2)):$((x * 2)):$((y * 2))" \
    "$output_dir/document-pict-${number}.png"
done

echo "Wrote display images to $output_dir"
