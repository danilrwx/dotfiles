-- Colours: match Claude Code's dark-ansi palette. termguicolors is off, so syntax
-- colour comes from the terminal's 16 ANSI slots (the same source dark-ansi uses):
-- keywords/builtins/nil/bool → magenta, strings → green, comments → grey, types →
-- cyan, rune literals → red, everything else (functions, numbers, variables) →
-- default fg. A few structural groups (menus/floats/markup) are linked underneath
-- and the ANSI palette overrides any capture it recognises.
vim.o.termguicolors = false

vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("yank_hl", { clear = true }),
  callback = function()
    vim.hl.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

-- trailing-whitespace highlight. matchadd is window-local, and fzf reuses the
-- window for its terminal, so always clear first (else the padded fzf header
-- stays highlighted red) and re-add only for normal file buffers.
local function ws_match()
  vim.fn.clearmatches()
  if vim.bo.buftype == "" then
    vim.fn.matchadd("ErrorMsg", [[\s\+$]])
  end
end
vim.api.nvim_create_autocmd({ "BufWinEnter", "TermOpen" }, {
  group = vim.api.nvim_create_augroup("ws_match", { clear = true }),
  callback = ws_match,
})

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

-- structural links applied first (below the ANSI palette): neutralise menus and
-- floats to Normal, colour markup by role. Non-capture groups (Pmenu/…) aren't in
-- the @-completion list, so they must be linked explicitly.
local LINKS = {
  Pmenu = "Normal",
  NormalFloat = "Normal",
  WinSeparator = "Normal",
  ["@property.yaml"] = "Type",
  ["@markup.heading"] = "Keyword",
  ["@markup.raw"] = "String",
  ["@markup.link"] = "Type",
  ["@punctuation.special.markdown"] = "Type",
}

local function target_for(g)
  if LINKS[g] then
    return LINKS[g]
  end
  for k, target in pairs(LINKS) do
    if g:find("^" .. k:gsub("%.", "%%.") .. "%.") then
      return target
    end
  end
  return "Normal"
end

local function apply()
  local hl = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end
  local captures = vim.fn.getcompletion("@", "highlight")
  -- 1) link every capture to a base group (unrecognised ones → Normal), then the
  --    non-capture structural groups.
  for _, g in ipairs(captures) do
    hl(g, { link = target_for(g) })
  end
  for g, target in pairs(LINKS) do
    hl(g, { link = target })
  end
  -- 2) ANSI palette on base + syntax groups, overriding the links it recognises.
  hl("Normal", { ctermfg = 15, ctermbg = "NONE" }) -- bright white, not the dull 7
  local groups = vim.list_extend(vim.deepcopy(captures), {
    "Keyword", "Statement", "Conditional", "Repeat", "Operator", "Character",
    "String", "Comment", "Type", "Function", "Number", "Float", "Constant",
    "Identifier",
  })
  for _, g in ipairs(groups) do
    local b = bucket(g)
    if b then
      hl(g, PALETTE[b])
    end
  end
  -- diff colours (gitsigns preview / diff floats): green +, red -, yellow ~
  for _, g in ipairs({ "Added", "diffAdded", "@diff.plus" }) do
    hl(g, { ctermfg = 10 })
  end
  for _, g in ipairs({ "Removed", "diffRemoved", "@diff.minus" }) do
    hl(g, { ctermfg = 9 })
  end
  for _, g in ipairs({ "Changed", "diffChanged", "@diff.delta" }) do
    hl(g, { ctermfg = 11 })
  end
  -- soften the loud default quickfix / statusline colours to muted greys
  hl("QuickFixLine", { ctermbg = 237, bold = true })
  hl("StatusLine", { ctermbg = 236, ctermfg = 245 })
  hl("StatusLineNC", { ctermbg = 234, ctermfg = 240 })
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("claudelook", { clear = true }),
  callback = apply,
})
vim.cmd.colorscheme("torte") -- fires ColorScheme → apply()
