# From0079To0093

原本の DOCX を Git で編集・拡張しやすいソースへ分解したディレクトリです。

- `chapters/rulebook.md`: 段落スタイルと表を変換した編集用本文
- `assets/media/`: 埋め込み画像（原形式）
- `assets/shapes/`: Word VML 図形の個別 XML と一覧
- `assets/ooxml/`: レイアウト、ヘッダー、図形配置を再現するための WordprocessingML 原本

Markdown は本文編集の起点です。複雑な表、テキストボックス、ページ上の配置は Markdown の表現域外のため、対応する XML を参照して段階的に再構成してください。

原本: `20071215_From0079_To0093.docx`  
作成者: Circle LLK
