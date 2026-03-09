require('mini.ai').setup()

require('mini.basics').setup()

require('mini.files').setup()

require('mini.align').setup()

require('mini.bracketed').setup()

require('mini.surround').setup()

require('mini.trailspace').setup()
vim.keymap.set('n', '<Leader>ds', ":lua MiniTrailspace.trim()<CR>", {})

require('mini.comment').setup()

require('mini.pairs').setup()

require('mini.statusline').setup()

require('mini.jump').setup()

require('mini.move').setup()
