_G.Funcs = {}

Funcs.toggle_quickfix = function()
  local quickfix_wins = vim.tbl_filter(
    function(win_id) return vim.fn.getwininfo(win_id)[1].quickfix == 1 end,
    vim.api.nvim_tabpage_list_wins(0)
  )

  local command = #quickfix_wins == 0 and "copen" or "cclose"
  vim.cmd(command)
end

Funcs.region_to_text = function(region)
  local text = ""
  local maxcol = vim.v.maxcol
  for line, cols in vim.spairs(region) do
    local endcol = cols[2] == maxcol and -1 or cols[2]
    local chunk = vim.api.nvim_buf_get_text(0, line, cols[1], line, endcol, {})[1]
    text = ("%s%s\n"):format(text, chunk)
  end
  return text
end

Funcs.visual_to_text = function()
  local r = vim.region(0, "'<", "'>", vim.fn.visualmode(), true)
  return Funcs.region_to_text(r)
end
