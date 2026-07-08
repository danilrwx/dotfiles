-- UI: highlight groups, floating windows, rendering. Knows nothing about
-- matching strategy, history or keymaps — it only draws what it is handed.
local M = {}
local ns = vim.api.nvim_create_namespace("picker")
local ns_cur = vim.api.nvim_create_namespace("picker_cur")
local hlns = vim.api.nvim_create_namespace("picker_hl")

-- fzf-like palette (mirrors FZF_DEFAULT_OPTS: match=blue, accents=green,
-- border=grey). default=true lets a colorscheme override.
local function setup_hl()
  local set = vim.api.nvim_set_hl
  set(0, "PickerBorder", { fg = "#6b7089", default = true })
  set(0, "PickerMatch", { fg = "#5fafff", bold = true, default = true })
  set(0, "PickerMatchFile", { fg = "#e0af68", bold = true, default = true })
  set(0, "PickerCurrent", { fg = "#00cd00", default = true })
  set(0, "PickerPointer", { fg = "#00cd00", bold = true, default = true })
  set(0, "PickerMarker", { fg = "#00cd00", default = true })
  set(0, "PickerCounter", { fg = "#5fafff", default = true })
  set(0, "PickerPrompt", { fg = "#dcdccc", bold = true, default = true })
end
setup_hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_hl })

local View = {}
View.__index = View

-- Build the three stacked floats (preview / results / prompt) and return a view.
function M.new(prompt_name, hint)
  local W, H = vim.o.columns, vim.o.lines
  local width, col = W - 2, 0
  local pv_h = math.floor(H * 0.5)
  local ls_h = math.max(3, H - pv_h - 1 - 8)

  local function float(row, h, cfg)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].bufhidden = "wipe" -- drop the scratch buffer with its window
    local win = vim.api.nvim_open_win(buf, false, vim.tbl_extend("force", {
      relative = "editor",
      row = row,
      col = col,
      width = width,
      height = h,
      border = "single",
      style = "minimal",
      zindex = 50,
    }, cfg or {}))
    vim.wo[win].winhighlight = "FloatBorder:PickerBorder,FloatTitle:PickerPrompt,Normal:Normal"
    return win, buf
  end

  local v = setmetatable({ prev_visible = true, page = math.max(1, ls_h - 1) }, View)
  v.prev_win, v.prev_buf = float(0, pv_h, { title = " preview " })
  v.list_win, v.list_buf = float(pv_h + 2, ls_h, {})
  v.prompt_win, v.prompt_buf = float(pv_h + 2 + ls_h + 2, 1,
    { title = " " .. prompt_name .. " ", title_pos = "left" })

  vim.wo[v.prev_win].number = false
  vim.wo[v.list_win].signcolumn = "yes:1"
  vim.wo[v.prompt_win].statuscolumn = "%#PickerPrompt#> "
  vim.bo[v.prompt_buf].buftype = "nofile"
  pcall(vim.api.nvim_win_set_config, v.list_win,
    { footer = { { " " .. hint .. " ", "PickerBorder" } }, footer_pos = "center" })
  vim.api.nvim_set_current_win(v.prompt_win)
  return v
end

function View:query()
  return vim.api.nvim_buf_get_lines(self.prompt_buf, 0, 1, false)[1] or ""
end

function View:set_query(text)
  vim.api.nvim_buf_set_lines(self.prompt_buf, 0, 1, false, { text or "" })
end

function View:set_title(text)
  pcall(vim.api.nvim_win_set_config, self.prompt_win,
    { title = " " .. text .. " ", title_pos = "left" })
end

function View:focus(col)
  vim.cmd("startinsert")
  vim.api.nvim_win_set_cursor(self.prompt_win, { 1, col or 0 })
end

-- Full rebuild: list buffer + mark/match highlights (bounded to 500 rows; the
-- buffer still holds every row so navigation stays in sync with the preview).
-- positions[i] = list of { col = 0-based byte, hl = group } for filtered[i], or
-- nil when there's no active query.
function View:render_list(filtered, marked, positions)
  vim.bo[self.list_buf].modifiable = true
  vim.api.nvim_buf_set_lines(self.list_buf, 0, -1, false, filtered)
  vim.bo[self.list_buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(self.list_buf, ns, 0, -1)
  for i = 1, math.min(#filtered, 500) do
    if marked[filtered[i]] then
      vim.api.nvim_buf_set_extmark(self.list_buf, ns, i - 1, 0,
        { sign_text = "+", sign_hl_group = "PickerMarker" })
    end
    if positions and positions[i] then
      for _, h in ipairs(positions[i]) do
        vim.api.nvim_buf_set_extmark(self.list_buf, ns, i - 1, h.col,
          { end_col = h.col + 1, hl_group = h.hl })
      end
    end
  end
end

-- Light: only the current-line highlight + cursor + counter. Safe per keystroke.
function View:point(sel, filtered, ncand, nmark)
  vim.api.nvim_buf_clear_namespace(self.list_buf, ns_cur, 0, -1)
  if #filtered > 0 and sel <= #filtered then
    vim.api.nvim_buf_set_extmark(self.list_buf, ns_cur, sel - 1, 0,
      { line_hl_group = "PickerCurrent", sign_text = ">", sign_hl_group = "PickerPointer" })
    pcall(vim.api.nvim_win_set_cursor, self.list_win, { sel, 0 })
    vim.api.nvim_win_call(self.list_win, function()
      vim.cmd("normal! zz")
    end)
  end
  local counter = string.format(" %d/%d%s ", #filtered, ncand, nmark > 0 and (" " .. nmark .. "*") or "")
  pcall(vim.api.nvim_win_set_config, self.prompt_win,
    { footer = { { counter, "PickerCounter" } }, footer_pos = "right" })
end

-- Render the previewed item ({file, lnum}) with treesitter highlighting.
function View:preview(item)
  if not vim.api.nvim_win_is_valid(self.prev_win) then
    return -- a debounced tick can fire after the picker closed
  end
  item = item or {}
  vim.bo[self.prev_buf].modifiable = true
  if not item.file or vim.fn.filereadable(item.file) == 0 then
    vim.api.nvim_buf_set_lines(self.prev_buf, 0, -1, false, {})
    vim.bo[self.prev_buf].modifiable = false
    return
  end
  vim.api.nvim_win_set_config(self.prev_win, { title = " " .. vim.fn.fnamemodify(item.file, ":t") .. " " })
  local lines = vim.fn.readfile(item.file, "", 500)
  -- readfile maps NUL bytes to \n; a line with \n means binary, which
  -- nvim_buf_set_lines rejects — show a placeholder.
  local binary = false
  for _, l in ipairs(lines) do
    if l:find("\n") then
      binary = true
      break
    end
  end
  if binary then
    lines = { "[binary file]" }
  end
  vim.api.nvim_buf_set_lines(self.prev_buf, 0, -1, false, lines)
  vim.bo[self.prev_buf].modifiable = false
  local ft = not binary and (vim.filetype.match({ filename = item.file, contents = lines }) or "") or ""
  vim.bo[self.prev_buf].filetype = ft
  if ft ~= "" then
    pcall(vim.treesitter.start, self.prev_buf)
  end
  vim.api.nvim_buf_clear_namespace(self.prev_buf, hlns, 0, -1)
  if item.lnum and item.lnum >= 1 and item.lnum <= #lines then
    vim.api.nvim_buf_set_extmark(self.prev_buf, hlns, item.lnum - 1, 0, { line_hl_group = "Visual" })
    pcall(vim.api.nvim_win_set_cursor, self.prev_win, { item.lnum, 0 })
    vim.api.nvim_win_call(self.prev_win, function()
      vim.cmd("normal! zz")
    end)
  end
end

function View:toggle_preview()
  self.prev_visible = not self.prev_visible
  pcall(vim.api.nvim_win_set_config, self.prev_win, { hide = not self.prev_visible })
end

function View:scroll_preview(down)
  if self.prev_visible then
    vim.api.nvim_win_call(self.prev_win, function()
      vim.cmd("normal! " .. (down and "\4" or "\21")) -- <C-d>/<C-u>
    end)
  end
end

function View:close()
  pcall(vim.cmd, "stopinsert")
  for _, w in ipairs({ self.prev_win, self.list_win, self.prompt_win }) do
    pcall(vim.api.nvim_win_close, w, true)
  end
end

return M
