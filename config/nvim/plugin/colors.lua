-- Colours after Alabaster: only a few things coloured, all the rest the plain
-- fg, so colour means something. termguicolors is off, so they come from the
-- terminal's 16 ANSI slots (alacritty's colors/, Claude's dark-ansi the same),
-- the bright ones only: comments → grey, definitions (where a function or type
-- is declared: after/queries) and control flow (branches, loops, return, goto,
-- the preprocessor's #if/#ifdef/#endif) → magenta, calls → blue, types → cyan,
-- strings → green. Literals, other keywords (struct, const) and variables stay
-- plain. Menus/floats/markup are linked underneath.
--
-- No borrowed colorscheme: `hi clear` (nvim's own defaults) and the UI groups set
-- here. The UI has no background of its own (statusline, tabs, splits, folds), so
-- the editor stays see-through like the terminal and the bar; selections are a
-- dark grey, the picked menu item and the matches bright green (ANSI 10),
-- diffs coloured by their text.
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
  comment = { ctermfg = 8 }, -- grey
  definition = { ctermfg = 13 }, -- bright magenta
  call = { ctermfg = 12 }, -- bright blue: function and method calls
  type = { ctermfg = 14 }, -- bright cyan: every type name, builtin ones too
  string = { ctermfg = 10 }, -- bright green
  flow = { ctermfg = 13 }, -- bright magenta, as definitions: if/else/switch, loops, break/continue, return, goto
  plain = {}, -- default fg: keywords, types, calls, variables
}

-- classify a treesitter capture (or standard group) into a palette bucket; nil
-- leaves a capture on its link (Normal, or LINKS below).
local function bucket(g)
  if g:match("^@comment") or g == "Comment" or g == "SpecialComment" then
    return "comment"
  elseif g:match("^@definition") then
    return "definition"
  -- control flow, where execution branches, loops or leaves; not the ternary's
  -- ? and :, which read as operators
  elseif (g:match("^@keyword%.conditional") and not g:match("ternary"))
    or g:match("^@keyword%.repeat") or g:match("^@keyword%.return")
    or g:match("^@keyword%.exception") then
    return "flow"
  elseif g:match("^@function%.call") or g:match("^@function%.method%.call")
    or g:match("^@function%.builtin") then
    return "call"
  elseif (g:match("^@type") and not g:match("qualifier")) or g == "Type"
    or g == "Typedef" or g == "Structure" then
    return "type"
  elseif g:match("^@string") or g == "String" then
    return "string"
  elseif not g:match("^@") then
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
  ["@property.yaml"] = "@definition", -- a key is what the file defines
  ["@markup.heading"] = "Title",
  ["@markup.raw"] = "String",
  ["@markup.link"] = "Underlined",
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
  -- the terminal's own text colour, the theme's foreground (bin/theme): slot 15 is not it everywhere
  hl("Normal", { ctermfg = "NONE", ctermbg = "NONE" })
  -- not in captures until a query uses them, so set by name
  hl("@definition", PALETTE.definition)
  -- the preprocessor's #if/#ifdef/#else/#endif branch too, at compile time
  for _, g in ipairs({ "@keyword.conditional", "@keyword.repeat", "@keyword.return", "@keyword.exception", "@keyword.directive" }) do
    hl(g, PALETTE.flow)
  end
  -- #define, and #pragma/#error (after/queries/c), would fall back to the
  -- magenta parent if left empty
  for _, g in ipairs({ "@keyword.directive.define", "@keyword.directive.other" }) do
    hl(g, { link = "Normal" })
  end
  for _, g in ipairs({ "@function.call", "@function.method.call", "@function.builtin" }) do
    hl(g, PALETTE.call)
  end
  for _, g in ipairs({ "@type", "@type.builtin", "@type.definition" }) do
    hl(g, PALETTE.type)
  end
  hl("@keyword.conditional.ternary", { link = "Normal" }) -- an empty group would fall back to the yellow parent
  local groups = vim.list_extend(vim.deepcopy(captures), {
    "Keyword", "Statement", "Conditional", "Repeat", "Operator", "Character",
    "String", "Comment", "SpecialComment", "Type", "Function", "Number", "Float",
    "Boolean", "Constant", "Identifier", "PreProc", "Include", "Define", "Macro",
    "PreCondit", "StorageClass", "Structure", "Typedef", "Label", "Exception",
    "Special", "SpecialChar", "Delimiter", "Tag",
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
  -- what is picked or current; what stands out is bold in the terminal's own
  -- text and search hits reversed, never white (15) or black (0), which swap
  -- places in the light themes
  local UI = {
    StatusLine = { bold = true },
    StatusLineNC = { ctermfg = 8 },
    StatusLineTerm = { bold = true },
    StatusLineTermNC = { ctermfg = 8 },
    TabLine = { ctermfg = 8 },
    TabLineSel = { bold = true },
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
    CursorLineNr = { bold = true },
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

    PmenuSel = { ctermfg = 10, ctermbg = 237, bold = true },
    PmenuKindSel = { ctermfg = 10, ctermbg = 237 },
    PmenuExtraSel = { ctermfg = 10, ctermbg = 237 },
    PmenuMatch = { ctermfg = 10 },
    PmenuMatchSel = { ctermfg = 10, ctermbg = 237, bold = true },
    PmenuSbar = {},
    PmenuThumb = { ctermbg = 8 },
    WildMenu = { ctermfg = 10, ctermbg = 237, bold = true },

    Search = { ctermfg = 10, ctermbg = 238, bold = true, underline = true },
    CurSearch = { ctermfg = 10, reverse = true },
    IncSearch = { ctermfg = 10, reverse = true },
    Substitute = { ctermfg = 10, reverse = true },

    DiffAdd = { ctermfg = 10 },
    DiffChange = { ctermfg = 11 },
    DiffDelete = { ctermfg = 9 },
    DiffText = { ctermfg = 11, bold = true, underline = true },

    Title = { bold = true },
    Directory = { ctermfg = 14 },
    ErrorMsg = { ctermfg = 9 },
    Error = { ctermfg = 9 },
    WarningMsg = { ctermfg = 11 },
    Todo = { ctermfg = 11, bold = true },
    Question = { ctermfg = 10 },
    MoreMsg = { ctermfg = 10 },
    ModeMsg = { bold = true },
    TrailingSpace = { ctermbg = 1 },
  }
  for g, opts in pairs(UI) do
    hl(g, opts)
  end
end

-- also on 'background': nvim sets it when the terminal reports a new ground
-- (bin/theme switching dark and light), and resets its own groups (Search's
-- yellow) with it
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("claudelook", { clear = true }),
  callback = apply,
})
vim.api.nvim_create_autocmd("OptionSet", {
  group = "claudelook",
  pattern = "background",
  -- after nvim's own reset, which comes once the option is set
  callback = function()
    vim.schedule(apply)
  end,
})

-- nvim's own defaults underneath, then ours; the ColorScheme autocmd above
-- re-applies them should another :colorscheme come in
vim.cmd("hi clear")
vim.g.colors_name = "claudelook"
apply()
