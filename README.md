# LLKUCルールブック

## このリポジトリについて
TRPGシステム、LLKUCのルールブック、ソースブックなどを Markdown ファイルをベースに作成するためのリポジトリです。

## 分解済みルールブック

`from0079-to0093/` は `output/20071215_From0079_To0093.docx` から取り出した編集用ソースです。

- `chapters/README.md`: 章・節へ分割した本文の目次
- `assets/media/`: DOCX 埋め込み画像
- `assets/shapes/`: 図形（VML）の個別 XML と一覧
- `assets/ooxml/`: ヘッダー、レイアウト、図形配置を含む WordprocessingML

同じ DOCX を再分解するには、リポジトリのルートで次を実行します。

```sh
ruby scripts/extract_docx.rb output/20071215_From0079_To0093.docx from0079-to0093
```

Markdown で表せないテキストボックスやページ上の配置は、対応する `assets/shapes/` と `assets/ooxml/` を原本として段階的に再構成します。

output/20071215_From0079_To0093.docx

## PDFビルド

Markdown 原稿から PDF を生成する設定は `from0079-to0093/` にあります。初回のみ、無料の Homebrew / BasicTeX 環境で次を実行します。

```sh
scripts/bootstrap-pdf-tools.sh
scripts/build-pdf.sh
scripts/verify-pdf.sh
```

PDF は `output/pdf/llkuc-rulebook.pdf`、ページ確認用 PNG は `tmp/pdfs/llkuc-rulebook/` に生成されます。収録順は `from0079-to0093/book-order.txt`、書誌情報と判型は `from0079-to0093/book.yaml`、組版は `from0079-to0093/styles/rulebook.tex` を編集してください。
### 図形の表示用画像を再生成する

Word由来の VML 図形は `assets/shapes/` に原本XMLとして残しています。Pandocでは直接描画できないため、元PDFから切り出した表示用PNGを `assets/figures/` に置いています。元PDFを `output/` に置いた状態で、次を実行すると再生成できます。

```sh
scripts/extract-figure-images.sh
```

