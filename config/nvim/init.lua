-- DOWNLOAD MINI.NVIM
local path_package = vim.fn.stdpath('data') .. '/site/'
local mini_path = path_package .. 'pack/deps/start/mini.nvim'
if not vim.loop.fs_stat(mini_path) then
  vim.cmd('echo "Installing `mini.nvim`" | redraw')
  local clone_cmd = { 'git', 'clone', '--filter=blob:none', 'https://github.com/echasnovski/mini.nvim', mini_path }
  vim.fn.system(clone_cmd)
  vim.cmd('packadd mini.nvim | helptags ALL')
  vim.cmd('echo "Installed `mini.nvim`" | redraw')
end
require('mini.deps').setup({ path = { package = path_package } })

-- PLUGINS

local MiniDeps = require('mini.deps')
local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

-- NOW STAGE

now(function()
  vim.o.termguicolors = true
  vim.cmd('colorscheme torte')
end)

now(function()
  require('mini.basics').setup({
    options = { basic = true, extra_ui = true, },
    mappings = { basic = true, windows = true, move_with_alt = true, },
  })
end)

now(function()
  add('nvim-tree/nvim-web-devicons')
  require('nvim-web-devicons').setup()
end)

now(function() require('mini.notify').setup() end)

now(function() require('mini.tabline').setup() end)

now(function() require('mini.statusline').setup() end)

now(function() require('mini.sessions').setup() end)

now(function() require('mini.starter').setup() end)

-- LATER STAGE

later(function() require('mini.ai').setup() end)

later(function() require('mini.align').setup() end)

later(function() require('mini.bracketed').setup() end)

later(function() require('mini.comment').setup() end)

later(function() require('mini.extra').setup() end)

later(function() require('mini.jump').setup() end)

later(function() require('mini.move').setup() end)

later(function() require('mini.diff').setup() end)

later(function() require('mini.pairs').setup() end)

later(function() require('mini.surround').setup() end)

later(function() require('mini.splitjoin').setup() end)

later(function()
  require('mini.files').setup()
  local MiniFiles = require('mini.files')
  vim.keymap.set('n', '<Tab>', function() if not MiniFiles.close() then MiniFiles.open() end end, {})
end)

later(function()
  require('mini.trailspace').setup()
  local MiniTrailspace = require('mini.trailspace')
  vim.keymap.set('n', '<Leader>ds', function() MiniTrailspace.trim() end, {})
end)

later(function()
  local hipatterns = require('mini.hipatterns')

  hipatterns.setup({
    highlighters = {
      fixme     = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'MiniHipatternsFixme' },
      hack      = { pattern = '%f[%w]()HACK()%f[%W]', group = 'MiniHipatternsHack' },
      todo      = { pattern = '%f[%w]()TODO()%f[%W]', group = 'MiniHipatternsTodo' },
      note      = { pattern = '%f[%w]()NOTE()%f[%W]', group = 'MiniHipatternsNote' },
      hex_color = hipatterns.gen_highlighter.hex_color(),
    },
  })
end)

later(function()
  require('mini.pick').setup()
  require('mini.fuzzy').setup()

  local MiniPick = require('mini.pick')
  vim.ui.select = MiniPick.ui_select
  vim.keymap.set('n', '<Leader><Leader>', function() MiniPick.builtin.files({ tool = 'git' }) end, {})
end)

later(function()
  add({
    source = 'nvim-treesitter/nvim-treesitter',
    checkout = 'master',
    monitor = 'master',
    hooks = { post_checkout = function() vim.cmd('TSUpdate') end },
  })

  require('nvim-treesitter.configs').setup({
    ensure_installed = { 'lua', 'vimdoc', 'ruby', 'go' },
    auto_install = true,
    highlight = { enable = true },
  })
end)

later(function()
  add({
    source = 'VonHeikemen/lsp-zero.nvim',
    checkout = 'v3.x',
    depends = {
      'L3MON4D3/LuaSnip',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-path',
      'hrsh7th/nvim-cmp',
      'neovim/nvim-lspconfig',
      'rafamadriz/friendly-snippets',
      'saadparwaiz1/cmp_luasnip',
      'williamboman/mason-lspconfig.nvim',
      'williamboman/mason.nvim',
    }
  })

  local lsp_zero = require('lsp-zero')
  lsp_zero.on_attach(function(_, bufnr)
    lsp_zero.default_keymaps({ buffer = bufnr })
  end)

  require('mason').setup({})
  require('mason-lspconfig').setup({
    handlers = {
      lsp_zero.default_setup,
      lua_ls = function()
        local lua_opts = lsp_zero.nvim_lua_ls()
        require('lspconfig').lua_ls.setup(lua_opts)
      end,
    }
  })

  local cmp = require('cmp')
  local cmp_action = lsp_zero.cmp_action()

  require('luasnip.loaders.from_vscode').lazy_load()

  cmp.setup({
    sources = {
      { name = 'path' },
      { name = 'nvim_lsp' },
      { name = 'luasnip', keyword_length = 2 },
      { name = 'buffer',  keyword_length = 3 },
    },
    window = {
      completion = cmp.config.window.bordered(),
      documentation = cmp.config.window.bordered(),
    },
    mapping = cmp.mapping.preset.insert({
      ['<Enter>'] = cmp.mapping.confirm({ select = true }),
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<C-u>'] = cmp.mapping.scroll_docs(-4),
      ['<C-d>'] = cmp.mapping.scroll_docs(4),
      ['<C-f>'] = cmp_action.luasnip_jump_forward(),
      ['<C-b>'] = cmp_action.luasnip_jump_backward(),
    }),
    formatting = lsp_zero.cmp_format({ details = true }),
    snippet = {
      expand = function(args)
        require('luasnip').lsp_expand(args.body)
      end,
    },
  })
end)

later(function()
  add('mbbill/undotree')

  vim.keymap.set('n', '<Leader>u', vim.cmd.UndotreeToggle)
end)

later(function()
  add({ source = 'gregorias/coerce.nvim' })

  require('coerce').setup()
end)

later(function()
  add({ source = 'chrisgrieser/nvim-spider' })

  require("spider").setup({
    skipInsignificantPunctuation = false,
    subwordMovement = true,
  })

  vim.keymap.set({ "n", "o", "x" }, "w", "<cmd>lua require('spider').motion('w')<CR>", { desc = "Spider-w" })
  vim.keymap.set({ "n", "o", "x" }, "e", "<cmd>lua require('spider').motion('e')<CR>", { desc = "Spider-e" })
  vim.keymap.set({ "n", "o", "x" }, "b", "<cmd>lua require('spider').motion('b')<CR>", { desc = "Spider-b" })
end)

later(function() add('slim-template/vim-slim') end)

-- KEYMAPS
local langmap_keys = {
  'ёЁ;`~', '№;#',
  'йЙ;qQ', 'цЦ;wW', 'уУ;eE', 'кК;rR', 'еЕ;tT', 'нН;yY', 'гГ;uU', 'шШ;iI', 'щЩ;oO', 'зЗ;pP', 'хХ;[{', 'ъЪ;]}',
  'фФ;aA', 'ыЫ;sS', 'вВ;dD', 'аА;fF', 'пП;gG', 'рР;hH', 'оО;jJ', 'лЛ;kK', 'дД;lL', [[жЖ;\;:]], [[эЭ;'\"]],
  'яЯ;zZ', 'чЧ;xX', 'сС;cC', 'мМ;vV', 'иИ;bB', 'тТ;nN', 'ьЬ;mM', [[бБ;\,<]], 'юЮ;.>',
}

vim.o.langmap = table.concat(langmap_keys, ',')

vim.keymap.set('n', '<A-q>', ':bd<CR>')

vim.keymap.set('n', '<Leader>s', [[:s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
vim.keymap.set('n', '<Leader>S', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

vim.keymap.set('n', '<Esc>', ':noh<Return><Esc>')

vim.keymap.set('n', '<C-g>', ':!topen-git<Return><Esc>')


-- SETTINGS
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.smarttab = true
vim.opt.smartindent = true
vim.opt.softtabstop = 2
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.colorcolumn = { 120 }
