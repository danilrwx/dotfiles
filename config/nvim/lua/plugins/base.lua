return {
  { import = "lazyvim.plugins.extras.coding.mini-surround" },
  { import = "lazyvim.plugins.extras.coding.yanky" },
  { import = "lazyvim.plugins.extras.dap.core" },
  { import = "lazyvim.plugins.extras.editor.mini-files" },
  { import = "lazyvim.plugins.extras.editor.refactoring" },
  { import = "lazyvim.plugins.extras.lang.docker" },
  { import = "lazyvim.plugins.extras.lang.git" },
  { import = "lazyvim.plugins.extras.lang.go" },
  { import = "lazyvim.plugins.extras.lang.helm" },
  { import = "lazyvim.plugins.extras.lang.json" },
  { import = "lazyvim.plugins.extras.lang.python" },
  { import = "lazyvim.plugins.extras.lang.ruby" },
  { import = "lazyvim.plugins.extras.lang.yaml" },
  { import = "lazyvim.plugins.extras.lsp.none-ls" },
  { import = "lazyvim.plugins.extras.test.core" },
  { import = "lazyvim.plugins.extras.ui.treesitter-context" },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "github_light",
    },
  },

  {
    "nvim-lualine/lualine.nvim",
    opts = {
      sections = {
        lualine_a = { "mode" },
        lualine_b = {},
        lualine_y = {},
        lualine_z = { "branch" },
        lualine_c = { { "filename", path = 1 } },
      },
    },
  },

  {
    "tpope/vim-fugitive",
    lazy = false,
    dependencies = { "shumphrey/fugitive-gitlab.vim", "tpope/vim-rhubarb" },
  },

  {
    "lewis6991/gitsigns.nvim",
    event = "LazyFile",
    opts = {
      signcolumn = true,
      current_line_blame = true,
      current_line_blame_opts = {
        delay = 300,
        virt_text_pos = "right_align",
      },
    },
  },

  {
    "akinsho/git-conflict.nvim",
    version = "*",
    config = true,
  },

  {
    "projekt0n/github-nvim-theme",
    lazy = false,
    priority = 1000,
    config = function()
      require("github-theme").setup({ options = { transparent = true } })
    end,
  },
  {
    "chrisgrieser/nvim-various-textobjs",
    lazy = false,
    opts = { useDefaultKeymaps = true },
  },

  {
    "Wansmer/treesj",
    keys = { "<space>m", { "<space>j", false }, { "<space>s", false } },
    dependencies = { "nvim-treesitter/nvim-treesitter" }, -- if you install parsers with `nvim-treesitter`
    opts = {},
  },

  {
    "echasnovski/mini.files",
    opts = {
      windows = { width_preview = 60 },
      options = { use_as_default_explorer = true },
    },
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      document_highlight = {
        enabled = false,
      },
      codelens = {
        enabled = true,
      },
      inlay_hints = {
        enabled = false,
      },
    },
  },

  {
    "Wansmer/symbol-usage.nvim",
    event = "LspAttach", -- need run before LspAttach if you use nvim 0.9. On 0.10 use 'LspAttach'
    opts = {
      kinds = {
        vim.lsp.protocol.SymbolKind.Function,
        vim.lsp.protocol.SymbolKind.Method,
        vim.lsp.protocol.SymbolKind.Interface,
        vim.lsp.protocol.SymbolKind.Constant,
      },
      definition = { enabled = true },
      implementation = { enabled = true },
      vt_position = "end_of_line",
    },
  },

  {
    "SCJangra/table-nvim",
    ft = "markdown",
    opts = {},
  },

  { "mbbill/undotree" },
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

  {
    "nvim-contrib/nvim-ginkgo",
    lazy = false,
  },
  {
    "nvim-neotest/neotest",
    lazy = true,
    dependencies = {
      "fredrikaverpil/neotest-golang",
      "nvim-contrib/nvim-ginkgo",
    },
    opts = {
      adapters = {
        -- ["neotest-golang"] = {
        --   go_test_args = { "-v", "-race", "-count=1", "-timeout=60s" },
        --   dap_go_enabled = true,
        --   testify_enabled = true,
        -- },
        ["nvim-ginkgo"] = {},
        -- require("nvim-ginkgo"),
      },
    },
  },
}
