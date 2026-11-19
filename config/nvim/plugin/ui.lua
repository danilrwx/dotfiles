-- Neutral menus over Vim's default syntax colours; terminal colours only.
local function apply()
  if vim.o.background == "light" then
    vim.cmd.source(vim.fn.expand("~/dotfiles/config/themes/light/vim.vim"))
    return
  end
  local groups = {
    LineNr = { ctermfg = 8 },
    CursorLineNr = { ctermfg = 8 },
    LineNrAbove = { ctermfg = 8 },
    LineNrBelow = { ctermfg = 8 },
    NormalFloat = { ctermfg = 15, ctermbg = 16 },
    FloatBorder = { ctermfg = 8, ctermbg = 16 },
    Pmenu = { ctermfg = 7, ctermbg = 235 },
    PmenuSel = { ctermfg = 15, ctermbg = 238, bold = true },
    PmenuKind = { ctermfg = 8, ctermbg = 235 },
    PmenuKindSel = { ctermfg = 7, ctermbg = 238 },
    PmenuExtra = { ctermfg = 8, ctermbg = 235 },
    PmenuExtraSel = { ctermfg = 7, ctermbg = 238 },
    PmenuMatch = { ctermfg = 15, ctermbg = 235, bold = true },
    PmenuMatchSel = { ctermfg = 15, ctermbg = 238, bold = true },
    PmenuSbar = { ctermbg = 235 },
    PmenuThumb = { ctermbg = 240 },
  }
  for name, opts in pairs(groups) do
    vim.api.nvim_set_hl(0, name, opts)
  end
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("neutral_ui", { clear = true }),
  callback = apply,
})
apply()

local current
local function sync_theme()
  local path = vim.fn.expand("~/.config/dotfiles/theme/name")
  local mode = vim.fn.filereadable(path) == 1 and vim.fn.readfile(path)[1] or "dark"
  if mode == current then return end
  current = mode
  vim.o.background = mode
  vim.o.termguicolors = mode == "light"
  vim.cmd.colorscheme("vim")
end
local desktop_theme = vim.api.nvim_create_augroup("desktop_theme", { clear = true })
vim.api.nvim_create_autocmd("FocusGained", {
  group = desktop_theme,
  nested = true,
  callback = sync_theme,
})
vim.api.nvim_create_autocmd("Signal", {
  group = desktop_theme,
  nested = true,
  pattern = "SIGUSR1",
  callback = sync_theme,
})
sync_theme()
