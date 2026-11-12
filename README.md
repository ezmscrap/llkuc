# LLKUCルールブック

## このリポジトリについて
TRPGシステム、LLKUCのルールブック、ソースブックなどを Markdown ファイルをベースに作成するためのリポジトリです。

## 分解済みルールブック

`from0079-to0093/` は `output/20071215_From0079_To0093.docx` から取り出した編集用ソースです。

- `chapters/rulebook.md`: 本文と表を Markdown 化した編集の起点
- `assets/media/`: DOCX 埋め込み画像
- `assets/shapes/`: 図形（VML）の個別 XML と一覧
- `assets/ooxml/`: ヘッダー、レイアウト、図形配置を含む WordprocessingML

同じ DOCX を再分解するには、リポジトリのルートで次を実行します。

```sh
ruby scripts/extract_docx.rb output/20071215_From0079_To0093.docx from0079-to0093
```

Markdown で表せないテキストボックスやページ上の配置は、対応する `assets/shapes/` と `assets/ooxml/` を原本として段階的に再構成します。

output/20071215_From0079_To0093.docx
