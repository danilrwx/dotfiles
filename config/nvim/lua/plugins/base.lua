return {
  {
    "vim-lualine/lualine.nvim",
    enabled = false,
  },

  {
    "folke/noice.nvim",
    enabled = false,
  },

  {
    "echasnovski/mini.files",
    opts = {
      windows = {
        width_focus = 50,
        width_nofocus = 35,
        preview = false,
      },
      options = {
        use_as_default_explorer = true,
      },
    },
  },

  {
    "folke/snacks.nvim",
    opts = {
      dashboard = { enabled = false },
      picker = {
        layout = {
          layout = {
            box = "vertical",
            backdrop = false,
            border = "none",
            { win = "preview", title = "{preview}", height = 0.5, border = "top" },
            { win = "input", height = 1, border = "rounded", title = "{title} {live} {flags}", title_pos = "center" },
            { win = "list", border = "none" },
          },
        },
      },
    },
  },

  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "nvim-neotest/nvim-nio" },
    keys = {
      {
        "<leader>du",
        function()
          require("dapui").toggle({ reset = true })
        end,
        desc = "Dap UI",
      },
    },
  },
}
