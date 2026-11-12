#!/usr/bin/env ruby
# frozen_string_literal: true

# Extract a .docx into a Git-friendly Markdown source tree. It intentionally
# retains the WordprocessingML package fragments that Markdown cannot express
# (VML shapes, drawing placement, headers, and page layout).

require 'fileutils'
require 'open3'
require 'rexml/document'
require 'rexml/xpath'
require 'yaml'

abort 'usage: scripts/extract_docx.rb INPUT.docx OUTPUT_DIR' unless ARGV.length == 2

input, output = ARGV
abort "not found: #{input}" unless File.file?(input)

NS = {
  'w' => 'http://schemas.openxmlformats.org/wordprocessingml/2006/main',
  'a' => 'http://schemas.openxmlformats.org/drawingml/2006/main',
  'r' => 'http://schemas.openxmlformats.org/officeDocument/2006/relationships',
  'v' => 'urn:schemas-microsoft-com:vml'
}.freeze

def zip_read(docx, member)
  text, status = Open3.capture2('unzip', '-p', docx, member)
  abort "could not read #{member}" unless status.success?
  text
end

def zip_members(docx)
  text, status = Open3.capture2('unzip', '-Z1', docx)
  abort 'could not list docx package' unless status.success?
  text.lines(chomp: true)
end

def element_text(element)
  output = +''
  REXML::XPath.each(element, './/w:t|.//w:tab|.//w:br|.//w:cr', NS) do |node|
    output << case node.name
              when 't' then node.text.to_s
              when 'tab' then "\t"
              else "\n"
              end
  end
  output.gsub(/\s+/, ' ').strip
end

def styled_text(paragraph)
  chunks = []
  REXML::XPath.each(paragraph, './w:r', NS) do |run|
    # Text boxes inside w:pict belong to a diagram, not to the surrounding
    # prose. The diagram is linked separately below.
    text = REXML::XPath.match(run, './/w:t', NS).reject do |node|
      parent = node.parent
      found = false
      while parent
        found ||= parent.name == 'pict'
        parent = parent.parent
      end
      found
    end.map { |node| node.text.to_s }.join.gsub(/\s+/, ' ').strip
    next if text.empty?
    properties = REXML::XPath.first(run, './w:rPr', NS)
    bold = properties && REXML::XPath.first(properties, './w:b', NS)
    italic = properties && REXML::XPath.first(properties, './w:i', NS)
    text = "**#{text}**" if bold
    text = "*#{text}*" if italic
    chunks << text
  end
  chunks.empty? ? element_text(paragraph) : chunks.join
end

def pict_links(paragraph, index)
  count = REXML::XPath.match(paragraph, './/w:pict', NS).length
  (1..count).map do |offset|
    number = index + offset
    filename = "document-pict-#{format('%03d', number)}.xml"
    "[図形データ: #{filename}](../assets/shapes/#{filename})"
  end
end

def paragraph_style(paragraph)
  node = REXML::XPath.first(paragraph, './w:pPr/w:pStyle', NS)
  node&.attributes&.get_attribute_ns(NS['w'], 'val')&.value
end

def relationship_targets(docx)
  xml = REXML::Document.new(zip_read(docx, 'word/_rels/document.xml.rels'))
  result = {}
  REXML::XPath.each(xml, '//*[local-name()="Relationship"]') do |rel|
    target = rel.attributes['Target']
    result[rel.attributes['Id']] = target if target&.start_with?('media/')
  end
  result
end

def image_links(paragraph, targets)
  ids = []
  REXML::XPath.each(paragraph, './/a:blip', NS) { |n| ids << n.attributes.get_attribute_ns(NS['r'], 'embed')&.value }
  REXML::XPath.each(paragraph, './/v:imagedata', NS) { |n| ids << n.attributes.get_attribute_ns(NS['r'], 'id')&.value }
  ids.compact.uniq.map { |id| targets[id] }.compact.map { |target| "![#{File.basename(target)}](../assets/media/#{File.basename(target)})" }
end

def markdown_table(table)
  rows = REXML::XPath.match(table, './w:tr', NS).map do |row|
    REXML::XPath.match(row, './w:tc', NS).map { |cell| element_text(cell).gsub('|', '\\|') }
  end
  return '' if rows.empty?
  width = rows.map(&:length).max
  rows.each { |row| row.fill('', row.length...width) }
  header = rows.shift
  (["| #{header.join(' | ')} |", "| #{Array.new(width, '---').join(' | ')} |"] + rows.map { |r| "| #{r.join(' | ')} |" }).join("\n")
end

FileUtils.mkdir_p(output)
%w[chapters assets/media assets/shapes assets/ooxml].each { |path| FileUtils.mkdir_p(File.join(output, path)) }

members = zip_members(input)
members.grep(%r{^word/media/}).each do |member|
  File.binwrite(File.join(output, 'assets/media', File.basename(member)), zip_read(input, member))
end

# Retain every Word XML fragment as source-of-truth for layout and unsupported
# elements; this makes re-conversion and targeted repairs possible.
xml_members = members.grep(%r{^word/.*\.xml$})
xml_members.each do |member|
  destination = File.join(output, 'assets/ooxml', member.sub(%r{^word/}, ''))
  FileUtils.mkdir_p(File.dirname(destination))
  File.binwrite(destination, zip_read(input, member))
end

# One file per VML drawing so it can be inspected or converted independently.
shape_manifest = []
xml_members.each do |member|
  xml = REXML::Document.new(zip_read(input, member))
  index = 0
  REXML::XPath.each(xml, '//w:pict', NS) do |shape|
    index += 1
    filename = "#{File.basename(member, '.xml')}-pict-#{format('%03d', index)}.xml"
    # A w:pict fragment inherits namespace declarations from its source part.
    # Give standalone files their own wrapper so ordinary XML tools can read it.
    fragment = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <llkuc:shape xmlns:llkuc="https://llkuc.example/ns/extracted-shape"
        xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
        xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
        xmlns:v="urn:schemas-microsoft-com:vml"
        xmlns:o="urn:schemas-microsoft-com:office:office"
        xmlns:w10="urn:schemas-microsoft-com:office:word"
        xmlns:w14="http://schemas.microsoft.com/office/word/2010/wordml">
      #{shape}
      </llkuc:shape>
    XML
    File.write(File.join(output, 'assets/shapes', filename), fragment)
    shape_manifest << { 'source_part' => member, 'file' => "assets/shapes/#{filename}", 'text' => element_text(shape) }
  end
end
File.write(File.join(output, 'assets/shapes/manifest.yml'), YAML.dump('shapes' => shape_manifest))

targets = relationship_targets(input)
document = REXML::Document.new(zip_read(input, 'word/document.xml'))
body = REXML::XPath.first(document, '//w:body', NS)
pict_index = 0
markdown = [
  '---',
  'title: "From 0079 to 0093"',
  'source: "20071215_From0079_To0093.docx"',
  'conversion: "scripts/extract_docx.rb"',
  '---',
  '',
  '<!-- 本文は Word の段落スタイル・表から機械変換した初稿です。',
  '     配置・テキストボックス・図形は assets/ooxml と assets/shapes を参照してください。 -->',
  ''
]

body.elements.each do |child|
  case child.name
  when 'p'
    text = styled_text(child)
    links = image_links(child, targets)
    shapes = pict_links(child, pict_index)
    pict_index += shapes.length
    style = paragraph_style(child)
    if !text.empty?
      if style&.match?(/^[1-5]$/)
        markdown << ('#' * style.to_i) + " #{text}"
      else
        markdown << text
      end
      markdown << ''
    end
    unless links.empty?
      markdown.concat(links)
      markdown << ''
    end
    unless shapes.empty?
      markdown.concat(shapes)
      markdown << ''
    end
  when 'tbl'
    table = markdown_table(child)
    unless table.empty?
      markdown << table
      markdown << ''
    end
  end
end

File.write(File.join(output, 'chapters/rulebook.md'), markdown.join("\n").rstrip + "\n")

metadata = REXML::Document.new(zip_read(input, 'docProps/core.xml'))
title = REXML::XPath.first(metadata, '//*[local-name()="title"]')&.text
creator = REXML::XPath.first(metadata, '//*[local-name()="creator"]')&.text
File.write(File.join(output, 'README.md'), <<~README)
  # #{title || File.basename(input, '.docx')}

  原本の DOCX を Git で編集・拡張しやすいソースへ分解したディレクトリです。

  - `chapters/rulebook.md`: 段落スタイルと表を変換した編集用本文
  - `assets/media/`: 埋め込み画像（原形式）
  - `assets/shapes/`: Word VML 図形の個別 XML と一覧
  - `assets/ooxml/`: レイアウト、ヘッダー、図形配置を再現するための WordprocessingML 原本

  Markdown は本文編集の起点です。複雑な表、テキストボックス、ページ上の配置は Markdown の表現域外のため、対応する XML を参照して段階的に再構成してください。

  原本: `#{File.basename(input)}`  
  作成者: #{creator || '不明'}
README

puts "Extracted #{members.grep(%r{^word/media/}).length} media files and #{shape_manifest.length} VML shapes to #{output}"
