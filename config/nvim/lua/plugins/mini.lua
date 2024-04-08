return {
  {
    'echasnovski/mini.nvim',
    version = false,
    config = function()
      require('mini.notify').setup()
      require('mini.ai').setup()
      require('mini.bracketed').setup()
      require('mini.comment').setup()
      require('mini.jump').setup()
      require('mini.move').setup()
      require('mini.pairs').setup()
      require('mini.surround').setup()
      require('mini.splitjoin').setup()

      require('mini.trailspace').setup()
      local MiniTrailspace = require('mini.trailspace')
      vim.keymap.set('n', '<Leader>ds', function() MiniTrailspace.trim() end, {})

      require('mini.files').setup()
      local MiniFiles = require('mini.files')
      vim.keymap.set('n', '<Tab>', function() if not MiniFiles.close() then MiniFiles.open() end end, {})
    end
  }
}
