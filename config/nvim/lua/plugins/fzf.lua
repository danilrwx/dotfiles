return {
  {
    "ibhagwan/fzf-lua",
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    lazy = false,
    opts = {
      winopts = {
        fullscreen = true,
        preview = {
          layout   = "vertical",
          vertical = "up:55%",
          border   = "single",
        }
      },
    },
    keys = {
      { "<leader>b",  "<cmd>lua require('fzf-lua').buffers()<cr>" },
      { "<leader>f",  "<cmd>lua require('fzf-lua').files()<cr>" },
      { "<leader>/",  "<cmd>lua require('fzf-lua').live_grep()<cr>" },
      { "<leader>'",  "<cmd>lua require('fzf-lua').resume()<cr>" },
      { "<leader>sb", "<cmd>lua require('fzf-lua').buffers()<cr>" },
      { "<leader>gs", "<cmd>lua require('fzf-lua').git_status()<cr>" },
      { "<leader>gB", "<cmd>lua require('fzf-lua').git_branches()<cr>" },
      { "<leader>ss", "<cmd>lua require('fzf-lua').git_branches()<cr>" },
      { "<leader>D", "<cmd>lua require('fzf-lua').lsp_workspace_diagnostics()<cr>" },
    }
  }
}
