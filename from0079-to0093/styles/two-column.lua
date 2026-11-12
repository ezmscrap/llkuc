-- Put chapters 1--9 in two columns without using LaTeX's global twocolumn
-- mode. Pandoc writes Markdown tables as longtable, which cannot be used
-- inside multicols. For these chapters, emit a compact non-floating tabular
-- instead so that the table remains in the surrounding text flow.

local columns_open = false

local function raw(tex)
  return pandoc.RawBlock('latex', tex)
end

local function chapter_number(header)
  local text = pandoc.utils.stringify(header.content)
  return tonumber(text:match('^%s*(%d+)'))
end

local function compact_table(table_block)
  local latex = pandoc.write(pandoc.Pandoc({table_block}), 'latex')
  latex = latex:gsub('^{\\def\\LTcaptype{none} %% do not increment counter\n', '')
  latex = latex:gsub('\\begin{longtable}%[%]%{', '\\begin{tabular}{')
  latex = latex:gsub('\\endhead\n\\bottomrule\\noalign{}\n\\endlastfoot\n', '')
  latex = latex:gsub('\\end{longtable}\n}', '\\bottomrule\n\\end{tabular}')
  return raw('\\begin{center}\\footnotesize\n' .. latex .. '\n\\end{center}')
end

function Pandoc(document)
  local result = {}

  for _, block in ipairs(document.blocks) do
    if block.t == 'Header' and block.level == 1 then
      if columns_open then
        table.insert(result, raw('\\end{multicols*}'))
        columns_open = false
      end

      table.insert(result, block)
      local number = chapter_number(block)
      if number and number >= 1 and number <= 9 then
        table.insert(result, raw('\\begin{multicols*}{2}'))
        columns_open = true
      end
    elseif block.t == 'Table' and columns_open then
      table.insert(result, compact_table(block))
    else
      table.insert(result, block)
    end
  end

  if columns_open then
    table.insert(result, raw('\\end{multicols*}'))
  end

  document.blocks = result
  return document
end
