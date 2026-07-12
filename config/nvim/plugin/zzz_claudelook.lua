-- Match Claude Code's dark-ansi syntax palette: colour comes from the terminal's
-- 16 ANSI slots (termguicolors off), the same source Claude uses in dark-ansi.
-- Loads last (zzz_) and re-runs on :colorscheme.
--
-- keywords + builtins + nil/bool → magenta, strings → green, comments → grey,
-- types → cyan, rune literals → red, everything else (functions, numbers,
-- variables) → default fg.
vim.o.termguicolors = false

local PALETTE = {
  keyword = { ctermfg = 13 }, -- magenta
  builtin = { ctermfg = 13 }, -- magenta: len, nil, true/false
  string = { ctermfg = 10 }, -- green
  comment = { ctermfg = 8 }, -- grey
  type = { ctermfg = 14 }, -- cyan
  character = { ctermfg = 9 }, -- red: rune literals
  plain = {}, -- default fg: functions, numbers, variables
}

-- classify a treesitter capture (or standard group) into a palette bucket.
-- builtins checked before keyword/plain so @function.builtin wins over @function.
local function bucket(g)
  if g:match("^@function%.builtin") or g:match("^@constant%.builtin")
    or g:match("^@variable%.builtin") or g:match("^@boolean") then
    return "builtin"
  elseif g:match("^@keyword") or g == "Keyword" or g == "Statement"
    or g == "Conditional" or g == "Repeat" or g == "Operator" then
    return "keyword"
  elseif g:match("^@character") or g == "Character" then
    return "character"
  elseif g:match("^@string") or g == "String" then
    return "string"
  elseif g:match("^@comment") or g == "Comment" then
    return "comment"
  elseif g:match("^@type") or g == "Type" then
    return "type"
  elseif g:match("^@function") or g:match("^@method") or g:match("^@number")
    or g:match("^@variable") or g:match("^@constant") or g == "Function"
    or g == "Number" or g == "Float" or g == "Constant" or g == "Identifier" then
    return "plain"
  end
  return nil
end

local function apply()
  -- default text = bright white (15), not the duller normal white (7)
  vim.api.nvim_set_hl(0, "Normal", { ctermfg = 15, ctermbg = "NONE" })

  local groups = vim.fn.getcompletion("@", "highlight")
  vim.list_extend(groups, {
    "Keyword", "Statement", "Conditional", "Repeat", "Operator", "Character",
    "String", "Comment", "Type", "Function", "Number", "Float", "Constant",
    "Identifier",
  })
  for _, g in ipairs(groups) do
    local b = bucket(g)
    if b then
      vim.api.nvim_set_hl(0, g, PALETTE[b])
    end
  end

  -- gitsigns preview (ghp) opens a 'diff' filetype float; colours.lua only set
  -- gui hex on these, so cterm shows white. Give them ANSI fg: green +, red -.
  for _, g in ipairs({ "Added", "diffAdded", "@diff.plus" }) do
    vim.api.nvim_set_hl(0, g, { ctermfg = 10 })
  end
  for _, g in ipairs({ "Removed", "diffRemoved", "@diff.minus" }) do
    vim.api.nvim_set_hl(0, g, { ctermfg = 9 })
  end
  for _, g in ipairs({ "Changed", "diffChanged", "@diff.delta" }) do
    vim.api.nvim_set_hl(0, g, { ctermfg = 11 })
  end

  -- soften the loud default quickfix / statusline colours to muted greys
  vim.api.nvim_set_hl(0, "QuickFixLine", { ctermbg = 237, bold = true })
  vim.api.nvim_set_hl(0, "StatusLine", { ctermbg = 236, ctermfg = 245 })
  vim.api.nvim_set_hl(0, "StatusLineNC", { ctermbg = 234, ctermfg = 240 })
end

vim.api.nvim_create_autocmd("ColorScheme", { callback = vim.schedule_wrap(apply) })
apply()
