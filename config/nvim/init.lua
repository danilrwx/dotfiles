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

-- LATER STAGE

later(function() require('mini.ai').setup() end)

later(function() require('mini.align').setup() end)

later(function() require('mini.bracketed').setup() end)

later(function() require('mini.comment').setup() end)

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
  add({
    source = 'nvim-telescope/telescope.nvim',
    depends = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope-project.nvim',
      'ThePrimeagen/harpoon',
      'sato-s/telescope-rails.nvim',
      'OliverChao/telescope-picker-list.nvim'
    },
  })

  local mark = require("harpoon.mark")
  local ui = require("harpoon.ui")

  vim.keymap.set("n", "<Leader>a", mark.add_file)
  vim.keymap.set("n", "<C-e>", ui.toggle_quick_menu)

  vim.keymap.set("n", "<C-h>", function() ui.nav_file(1) end)
  vim.keymap.set("n", "<C-j>", function() ui.nav_file(2) end)
  vim.keymap.set("n", "<C-k>", function() ui.nav_file(3) end)
  vim.keymap.set("n", "<C-l>", function() ui.nav_file(4) end)

  local builtin = require('telescope.builtin')
  local ext = require('telescope').extensions

  local project_actions = require('telescope._extensions.project.actions')
  require 'telescope'.setup {
    pickers = {
      colorscheme = {
        enable_preview = true
      }
    },
    extensions = {
      project = {
        base_dirs = {
          '~/w',
          '~/dotfiles'
        },
        hidden_files = true, -- default: false
        theme = 'dropdown',
        order_by = 'asc',
        search_by = 'title',
        on_project_selected = function(prompt_bufnr)
          project_actions.change_working_directory(prompt_bufnr, false)
          require('harpoon.ui').nav_file(1)
        end
      }
    },
  }

  require('telescope').load_extension('project')
  require("telescope").load_extension("rails")
  require("telescope").load_extension("picker_list")

  vim.keymap.set('n', '<Leader><Leader>', builtin.find_files, {})
  vim.keymap.set('n', '<Leader>fc', builtin.commands, {})
  vim.keymap.set('n', '<Leader>fs', builtin.live_grep, {})
  vim.keymap.set('x', '<Leader>fs', builtin.grep_string, {})
  vim.keymap.set('n', '<Leader>fds', builtin.lsp_document_symbols, {})
  vim.keymap.set('n', '<Leader>fws', builtin.lsp_workspace_symbols, {})
  vim.keymap.set('n', '<Leader>fg', builtin.git_commits, {})
  vim.keymap.set('n', '<Leader>fgb', builtin.git_bcommits, {})
  vim.keymap.set('x', '<Leader>fgb', builtin.git_bcommits_range, {})
  vim.keymap.set('n', '<Leader>b', builtin.buffers, {})
  vim.keymap.set('n', '<Leader>fq', builtin.quickfix, {})
  vim.keymap.set('n', '<Leader>fp', ext.project.project, {})
  vim.keymap.set('n', '<Leader>frm', ext.rails.models, {})
  vim.keymap.set('n', '<Leader>frc', ext.rails.controllers, {})
  vim.keymap.set('n', '<Leader>frv', ext.rails.views, {})
  vim.keymap.set('n', '<Leader>frs', ext.rails.specs, {})
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
