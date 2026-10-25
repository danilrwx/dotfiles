-- Markdown rendered in place, no plugin: extmarks over the builtin treesitter
-- tree. # markers hidden and headings coloured by level, bullets •◦▪, task boxes
-- ☐☑, quotes │, rules ─, table pipes │, code blocks on a dark band; the inline
-- markup (`code`, **bold**, links, fences) is concealed by nvim's own queries,
-- conceallevel=2 is all it needs. The cursor line shows the raw text.
--
-- Headings keep the text size: colour and bold carry the hierarchy (MdH1...MdH6),
-- so nothing here needs the terminal's text sizing protocol, and a multiplexer or
-- ssh reads the same as kitty itself.

local ns = vim.api.nvim_create_namespace("markdown_render")

local function set_hl()
  local hl = function(name, opts)
    opts.default = true
    vim.api.nvim_set_hl(0, name, opts)
  end
  hl("MdH1", { ctermfg = 13, bold = true })
  hl("MdH2", { ctermfg = 12, bold = true })
  hl("MdH3", { ctermfg = 14, bold = true })
  hl("MdH4", { ctermfg = 10, bold = true })
  hl("MdH5", { bold = true })
  hl("MdH6", { ctermfg = 8, bold = true })
  hl("MdBullet", { ctermfg = 8 })
  hl("MdDone", { ctermfg = 10 })
  hl("MdQuote", { ctermfg = 8 })
  hl("MdRule", { ctermfg = 8 })
  hl("MdCode", { ctermbg = 235 })
end
set_hl()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("markdown_hl", { clear = true }),
  callback = set_hl,
})

local BULLETS = { "•", "◦", "▪" }

local query = vim.treesitter.query.parse("markdown", [[
  (atx_heading) @heading
  [(list_marker_minus) (list_marker_plus) (list_marker_star)] @bullet
  (task_list_marker_unchecked) @todo
  (task_list_marker_checked) @done
  (block_quote) @quote
  (thematic_break) @rule
  (code_fence_content) @code
  (pipe_table_delimiter_row) @tdelim
  (pipe_table_header "|" @pipe)
  (pipe_table_row "|" @pipe)
]])

local function mark(buf, row, col, opts)
  pcall(vim.api.nvim_buf_set_extmark, buf, ns, row, col, opts)
end

-- the narrowest window showing buf: a rule spans what all of them show
local function text_width(buf)
  local w = math.huge
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    local info = vim.fn.getwininfo(win)[1]
    w = math.min(w, info.width - info.textoff)
  end
  return w
end

local handlers = {}

function handlers.heading(buf, node)
  local row, col = node:range()
  local marker = node:child(0)
  local level = tonumber(marker:type():match("atx_h(%d)_marker"))
  local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
  local group = "MdH" .. level
  mark(buf, row, 0, { end_col = #line, hl_group = group, priority = 200 })

  -- the marker and the space after it hidden: the text starts at the margin
  local _, _, _, mend = marker:range()
  mark(buf, row, col, { end_col = math.min(mend + 1, #line), conceal = "" })
end

-- how many of node's ancestors are of type t
local function depth(node, t)
  local d = 0
  local p = node:parent()
  while p do
    if p:type() == t then
      d = d + 1
    end
    p = p:parent()
  end
  return d
end

function handlers.bullet(buf, node)
  local row, col = node:range()
  local next = node:next_sibling()
  if next and next:type():match("^task_list_marker") then
    mark(buf, row, col, { end_col = col + 2, conceal = "" })
    return
  end
  local b = BULLETS[(depth(node, "list") - 1) % #BULLETS + 1]
  mark(buf, row, col, { end_col = col + 1, conceal = b, hl_group = "MdBullet" })
end

function handlers.todo(buf, node)
  local row, col, _, ecol = node:range()
  mark(buf, row, col, { end_col = ecol, conceal = "☐" })
end

function handlers.done(buf, node)
  local row, col, _, ecol = node:range()
  mark(buf, row, col, { end_col = ecol, conceal = "☑", hl_group = "MdDone" })
end

-- every > in a line's leading run, so nested quotes get one bar each; from the
-- outermost quote only, an inner one is in its lines already. The bar is the
-- table's │ (a rule, not a block), and the line's text goes grey as a quote
-- reads; a line of the quote carrying no > of its own (a lazy continuation) has
-- nothing to conceal, so the rule goes in as virtual text at the outermost
-- bar's column, and the rule stays unbroken
function handlers.quote(buf, node)
  if depth(node, "block_quote") > 0 then
    return
  end
  local srow, _, erow, ecol = node:range()
  if ecol == 0 then
    erow = erow - 1
  end
  local bars, base = {}, nil
  for row = srow, erow do
    local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
    local cols = {}
    for col in line:match("^[%s>]*"):gmatch("()>") do
      cols[#cols + 1] = col - 1
    end
    bars[row] = cols
    if cols[1] and (not base or cols[1] < base) then
      base = cols[1]
    end
  end
  base = base or 0
  for row = srow, erow do
    local cols = bars[row]
    if #cols == 0 then
      -- nothing to conceal on a lazy continuation: its text starts at column 0,
      -- so the rule goes in as virtual text, indented to the outermost bar's
      -- column and followed by the space the > lines carry
      mark(buf, row, 0, {
        virt_text = { { (" "):rep(base) .. "│ ", "MdQuote" } },
        virt_text_pos = "inline",
      })
    else
      for _, col in ipairs(cols) do
        mark(buf, row, col, { end_col = col + 1, conceal = "│", hl_group = "MdQuote" })
      end
    end
    mark(buf, row, 0, { line_hl_group = "MdQuote" })
  end
end

function handlers.rule(buf, node)
  local row = node:range()
  mark(buf, row, 0, { virt_text = { { ("─"):rep(text_width(buf)), "MdRule" } }, virt_text_pos = "overlay" })
end

function handlers.code(buf, node)
  local srow, _, erow = node:range()
  for row = srow, erow - 1 do
    mark(buf, row, 0, { line_hl_group = "MdCode" })
  end
end

function handlers.pipe(buf, node)
  local row, col = node:range()
  mark(buf, row, col, { end_col = col + 1, conceal = "│", hl_group = "MdRule" })
end

-- |---|:--:| drawn as ├───┼────┤
function handlers.tdelim(buf, node)
  local row = node:range()
  local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
  local first, last = line:find("|"), #line - (line:reverse():find("|") or 1) + 1
  local s = line:gsub("()(.)", function(i, c)
    if c == "|" then
      return i == first and "├" or i == last and "┤" or "┼"
    end
    return c:match("%s") and c or "─"
  end)
  mark(buf, row, 0, { virt_text = { { s, "MdRule" } }, virt_text_pos = "overlay" })
end

-- ponytail: the whole buffer re-rendered on each change, fine for documents of
-- a few thousand lines; a range from on_bytes if a big file ever stutters.
local function render(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local parser = vim.treesitter.get_parser(buf, "markdown", { error = false })
  if not parser then
    return
  end
  local tree = parser:parse()[1]
  for id, node in query:iter_captures(tree:root(), buf) do
    handlers[query.captures[id]](buf, node)
  end
end

local group = vim.api.nvim_create_augroup("markdown_render", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "markdown",
  callback = function(ev)
    vim.wo[0][0].conceallevel = 2
    vim.wo[0][0].wrap = true
    vim.wo[0][0].linebreak = true
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufWinEnter" }, {
      group = group,
      buffer = ev.buf,
      callback = function()
        render(ev.buf)
      end,
    })
    render(ev.buf)
  end,
})
