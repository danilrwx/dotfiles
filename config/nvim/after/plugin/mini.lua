require('mini.files').setup()

require('mini.basics').setup()

require('mini.align').setup()

require('mini.operators').setup()

require('mini.move').setup()

require('mini.bracketed').setup()

require('mini.notify').setup()

require('mini.surround').setup()

require('mini.trailspace').setup()

require('mini.comment').setup()

require('mini.pairs').setup()

require('mini.jump').setup()

require('mini.move').setup()

require('mini.statusline').setup()

require('mini.tabline').setup()

vim.keymap.set('n', '<Tab>', function() if not MiniFiles.close() then MiniFiles.open() end end, {})
vim.keymap.set('n', '<Leader>ds', function() MiniTrailspace.trim() end, {})

