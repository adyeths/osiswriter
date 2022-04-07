--
-- Invoke with: pandoc -t osis.lua
--

-- This variable lets us add at least 1 level of chapter div in a document
gotheader = false


local pipe = pandoc.pipe
local stringify = (require "pandoc.utils").stringify

-- The global variable PANDOC_DOCUMENT contains the full AST of
-- the document which is going to be written. It can be used to
-- configure the writer.
local meta = PANDOC_DOCUMENT.meta

-- Character escaping
local function escape(s, in_attribute)
  return s:gsub("[<>&]",
    function(x)
      if x == '<' then
        return '&lt;'
      elseif x == '>' then
        return '&gt;'
      elseif x == '&' then
        return '&amp;'
      else
        return x
      end
    end)
end

-- Helper function to convert an attributes table into
-- a string that can be put into HTML tags.
local function attributes(attr)
  local attr_table = {}
  for x,y in pairs(attr) do
    if y and y ~= "" then
      table.insert(attr_table, ' ' .. x .. '="' .. escape(y,true) .. '"')
    end
  end
  return table.concat(attr_table)
end

-- Table to store footnotes, so they can be included at the end.
local notes = {}

-- Blocksep is used to separate block elements.
function Blocksep()
  return "\n\n"
end

-- This function is called once for the whole document. Parameters:
-- body is a string, metadata is a table, variables is a table.
-- This gives you a fragment.  You could use the metadata table to
-- fill variables in a custom lua template.  Or, pass `--template=...`
-- to pandoc, and pandoc will do the template processing as usual.
function Doc(body, metadata, variables)
  local buffer = {}
  local hbuffer = {}
  local header = [[<?xml version="1.0" encoding="UTF-8"?>

<osis xsi:schemaLocation="http://www.bibletechnologies.net/2003/OSIS/namespace
      http://www.bibletechnologies.net/osisCore.2.1.1.xsd"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xmlns="http://www.bibletechnologies.net/2003/OSIS/namespace">
<osisText osisRefWork="GenBook" xml:lang="en" osisIDWork="WorkID">
]]
  local footer = [[</div>
</osisText>
</osis>
]]
  local function add(s)
    table.insert(buffer, s)
  end

  table.insert(hbuffer, '<header>\n<work osisWork="WorkID">')
  if metadata.title then
    table.insert(hbuffer, '<title>' .. metadata.title .. '</title>')
  else
    table.insert(hbuffer, '<title>OSISGenbook</title>')
  end
  if metadata.author then
    table.insert(hbuffer, '<creator role="aut">' .. metadata.author .. '</creator>')
  end
  table.insert(hbuffer, [[</work>
<work osisWork="Bible">
<refSystem>Bible</refSystem>
</work>
</header>

<div type="book" osisID="Book">
]])


  add(header)
  add(table.concat(hbuffer, "\n"))
  add(body)

  if gotheader == true then
    add("</div>")
  end

  add(footer)


  return table.concat(buffer,'\n') .. '\n'
end

-- The functions that follow render corresponding pandoc elements.
-- s is always a string, attr is always a table of attributes, and
-- items is always an array of strings (the items in a list).
-- Comments indicate the types of other variables.

function Str(s)
  return escape(s)
end

function Space()
  return " "
end

function SoftBreak()
  return "\n"
end

function LineBreak()
  return "<lb/>\n"
end

function Emph(s)
  return "<hi type='emphasis'>" .. s .. "</hi>"
end

function Strong(s)
  return "<hi type='bold'>" .. s .. "</hi>"
end

function Subscript(s)
  return "<hi type='sub'>" .. s .. "</hi>"
end

function Superscript(s)
  return "<hi type='super'>" .. s .. "</hi>"
end

function SmallCaps(s)
  return '<hi type="small-caps">' .. s .. '</hi>'
end

function Strikeout(s)
  return '<hi type="line-through">' .. s .. '</hil>'
end

function Link(s, src, tit, attr)
  -- TODO: Fix this so links work in osis
  return s
  -- return "<a href='" .. escape(src,true) .. "' title='" ..
  --        escape(tit,true) .. "'>" .. s .. "</a>"
end

function Image(s, src, tit, attr)
  return "<figure src='" .. escape(src,true) .. "' alt='" ..
         escape(tit,true) .. "'/>"
end

function Code(s, attr)
  return ''
end

function InlineMath(s)
  return ''
end

function DisplayMath(s)
  return ''
end

function SingleQuoted(s)
  return "‘" .. s .. "’"
end

function DoubleQuoted(s)
  return "“" .. s .. "”"
end

function Note(s)
  return '<note type="x-footnote">' .. s .. '</note>'
end

function Span(s, attr)
  local attrib = attributes(attr)
  if attrib ~= "" then
    return "<!-- span " .. attrib .. " -->" .. s .. "<!-- end span -->"
  else
    return s
  end
end

function RawInline(format, str)
  return ''
end

function Cite(s, cs)
  -- local ids = {}
  -- for _,cit in ipairs(cs) do
  --   table.insert(ids, cit.citationId)
  -- end
  -- return "<span class=\"cite\" data-citation-ids=\"" .. table.concat(ids, ",") ..
  --   "\">" .. s .. "</span>"
  return s
end

function Plain(s)
  return s
end

function Para(s)
  return "<p>" .. s .. "</p>"
end

-- lev is an integer, the header level.
function Header(lev, s, attr)
  if lev == 1 then
    local oid = s
    oid = string.gsub(oid, '[^%w ]', '')
    if gotheader == true then
      return '</div>\n<div type="chapter" osisID="' .. oid .. '">\n<title level="' .. lev .. '" type="main">' .. s .. '</title>'
    else
      gotheader = true
      return '<div type="chapter" osisID="' .. oid .. '">\n<title level="' .. lev .. '" type="main">' .. s .. '</title>'
    end
  else
    return '<title level="' .. lev .. '" type="main">' .. s .. '</title>'
  end
end

function BlockQuote(s)
  return '<q type="block">\n' .. s .. '\n</q>'
end

function HorizontalRule()
  return ''
end

function LineBlock(ls)
  local buffer = {}
  for _, item in pairs(ls) do
    table.insert(buffer, "<l>" .. item .. "</l>")
  end
  return '<lg>\n' .. table.concat(buffer, '\n') .. '\n</lg>'
end

function CodeBlock(s, attr)
  return ''
end

function BulletList(items)
  local buffer = {}
  for _, item in pairs(items) do
    table.insert(buffer, "<item>" .. item .. "</item>")
  end
  return '<list type="x-unordered">\n' .. table.concat(buffer, '\n') .. '\n</list>'
end

function OrderedList(items)
  local buffer = {}
  for _, item in pairs(items) do
    table.insert(buffer, "<item>" .. item .. "</item>")
  end
  return '<list type="x-ordered">\n' .. table.concat(buffer, '\n') .. '\n</list>'
end

function DefinitionList(items)
  local buffer = {}
  for _,item in pairs(items) do
    local k, v = next(item)
    table.insert(buffer, "<item><hi type='bold'>" .. k .. "</hi></item>\n<list><item>" ..
                   table.concat(v, "</item>\n<item>") .. "</item></list>")
  end
  return '<list type="x-definition">\n' .. table.concat(buffer, '\n') .. '\n</list>'
end

function CaptionedImage(src, tit, caption, attr)
   return '<figure src="' .. escape(src,true) .. '"/>\n' ..
      '<p>' .. caption .. '</p>\n'
end

-- Caption is a string, aligns is an array of strings,
-- widths is an array of floats, headers is an array of
-- strings, rows is an array of arrays of strings.
function Table(caption, aligns, widths, headers, rows)
  local buffer = {}
  local function add(s)
    table.insert(buffer, s)
  end
  add("<table>")
  -- if caption ~= "" then
  --   add("<caption>" .. caption .. "</caption>")
  -- end
  if widths and widths[1] ~= 0 then
    for _, w in pairs(widths) do
      add('<cell />')
    end
  end
  local header_row = {}
  local empty_header = true
  for i, h in pairs(headers) do
    table.insert(header_row,'<cell role="label">' .. h .. '</cell>')
    empty_header = empty_header and h == ""
  end
  if empty_header then
    head = ""
  else
    add('<row>')
    for _,h in pairs(header_row) do
      add(h)
    end
    add('</row>')
  end
  for _, row in pairs(rows) do
    add('<row>')
    for i,c in pairs(row) do
      add('<cell>' .. c .. '</cell>')
    end
    add('</row>')
  end
  add('</table>')
  return table.concat(buffer,'\n')
end

function RawBlock(format, str)
  return ''
end

function Div(s, attr)
  local attrib = attributes(attr)
  if attrib ~= "" then
    return "<!-- div " .. attrib .. " -->\n" .. s .. "\n<!-- div end -->\n"
  else
    return s
  end
end

-- The following code will produce runtime warnings when you haven't defined
-- all of the functions you need for the custom writer, so it's useful
-- to include when you're working on a writer.
local meta = {}
meta.__index =
  function(_, key)
    io.stderr:write(string.format("WARNING: Undefined function '%s'\n",key))
    return function() return "" end
  end
setmetatable(_G, meta)

