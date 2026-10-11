-- Colours: match Claude Code's dark-ansi palette. termguicolors is off, so syntax
-- colour comes from the terminal's 16 ANSI slots (the same source dark-ansi uses):
-- keywords/builtins/nil/bool → magenta, strings → green, comments → grey, types →
-- cyan, rune literals → red, everything else (functions, numbers, variables) →
-- default fg. A few structural groups (menus/floats/markup) are linked underneath
-- and the ANSI palette overrides any capture it recognises.
--
-- No borrowed colorscheme: `hi clear` (nvim's own defaults) and the UI groups set
-- here. The UI has no background of its own (statusline, tabs, splits, folds), so
-- the editor stays see-through over bin/theme's wallpaper like the terminal and
-- the bar; selections are a dark grey, the picked menu item and the current match
-- the bar's green (ANSI 2), diffs coloured by their text.
vim.o.termguicolors = false

vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("yank_hl", { clear = true }),
  callback = function()
    vim.hl.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

-- trailing-whitespace highlight. matchadd is window-local and a window gets
-- reused for terminal/scratch buffers (lazygit, the picker), so always clear
-- first and re-add only for normal file buffers.
local function ws_match()
  vim.fn.clearmatches()
  if vim.bo.buftype == "" then
    vim.fn.matchadd("TrailingSpace", [[\s\+$]])
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

  -- the UI: text colours over no background, dark grey for selections, green for
  -- what is picked or current
  local UI = {
    StatusLine = { ctermfg = 15 },
    StatusLineNC = { ctermfg = 8 },
    StatusLineTerm = { ctermfg = 15 },
    StatusLineTermNC = { ctermfg = 8 },
    TabLine = { ctermfg = 8 },
    TabLineSel = { ctermfg = 15, bold = true },
    TabLineFill = {},
    WinSeparator = { ctermfg = 8 },
    VertSplit = { ctermfg = 8 },
    MsgSeparator = { ctermfg = 8 },
    FloatBorder = { ctermfg = 8 },
    Folded = { ctermfg = 8, italic = true },
    FoldColumn = { ctermfg = 8 },
    SignColumn = {},
    LineNr = { ctermfg = 8 },
    CursorLine = {},
    CursorColumn = { ctermbg = 235 },
    CursorLineNr = { ctermfg = 15, bold = true },
    CursorLineSign = {},
    CursorLineFold = {},
    ColorColumn = { ctermbg = 235 },
    NonText = { ctermfg = 8 },
    Whitespace = { ctermfg = 8 },
    SpecialKey = { ctermfg = 8 },
    EndOfBuffer = { ctermfg = 8 },

    Visual = { ctermbg = 238 },
    VisualNOS = { ctermbg = 238 },
    LspReferenceText = { ctermbg = 237 },
    LspReferenceRead = { ctermbg = 237 },
    LspReferenceWrite = { ctermbg = 237 },
    LspReferenceTarget = { ctermbg = 237 },
    LspSignatureActiveParameter = { bold = true, underline = true },
    MatchParen = { bold = true, underline = true },
    QuickFixLine = { ctermbg = 237, bold = true },

    PmenuSel = { ctermfg = 2, ctermbg = 237, bold = true },
    PmenuKindSel = { ctermfg = 2, ctermbg = 237 },
    PmenuExtraSel = { ctermfg = 2, ctermbg = 237 },
    PmenuMatch = { ctermfg = 2 },
    PmenuMatchSel = { ctermfg = 2, ctermbg = 237, bold = true },
    PmenuSbar = {},
    PmenuThumb = { ctermbg = 8 },
    WildMenu = { ctermfg = 2, ctermbg = 237, bold = true },

    Search = { ctermfg = 11, ctermbg = 237 },
    CurSearch = { ctermfg = 0, ctermbg = 2 },
    IncSearch = { ctermfg = 0, ctermbg = 2 },
    Substitute = { ctermfg = 0, ctermbg = 2 },

    DiffAdd = { ctermfg = 10 },
    DiffChange = { ctermfg = 11 },
    DiffDelete = { ctermfg = 9 },
    DiffText = { ctermfg = 11, bold = true, underline = true },

    Title = { ctermfg = 15, bold = true },
    Directory = { ctermfg = 14 },
    ErrorMsg = { ctermfg = 9 },
    Error = { ctermfg = 9 },
    WarningMsg = { ctermfg = 11 },
    Todo = { ctermfg = 11, bold = true },
    Question = { ctermfg = 2 },
    MoreMsg = { ctermfg = 2 },
    ModeMsg = { ctermfg = 15, bold = true },
    TrailingSpace = { ctermbg = 1 },
  }
  for g, opts in pairs(UI) do
    hl(g, opts)
  end
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("claudelook", { clear = true }),
  callback = apply,
})

-- nvim's own defaults underneath, then ours; the ColorScheme autocmd above
-- re-applies them should another :colorscheme come in
vim.cmd("hi clear")
vim.g.colors_name = "claudelook"
apply()
