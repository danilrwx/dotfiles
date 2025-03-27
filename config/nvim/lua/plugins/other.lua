return {
  {
    "mbbill/undotree",
    config = function() vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle) end,
  },

  {
    'sainnhe/gruvbox-material',
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.gruvbox_material_background = 'hard'
      vim.g.gruvbox_material_enable_italic = true
      vim.g.gruvbox_material_transparent_background = 1
      vim.cmd.colorscheme('gruvbox-material')
    end
  }
}
