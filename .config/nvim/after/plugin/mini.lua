
require('mini.files').setup()
local minifiles_toggle = function()
  if not MiniFiles.close() then MiniFiles.open() end
end
vim.keymap.set('n', '<Tab>', minifiles_toggle, {})

require('mini.align').setup()

require('mini.bracketed').setup()

require('mini.surround').setup()

require('mini.trailspace').setup()
vim.keymap.set('n', '<Leader>ds', function() MiniTrailspace.trim() end, {})

require('mini.comment').setup()

require('mini.pairs').setup()

require('mini.jump').setup()

require('mini.move').setup()
