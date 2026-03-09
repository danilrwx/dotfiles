return {
  {
    "tpope/vim-fugitive",
    lazy = false,
    keys = {
      { "<leader>g=", "<cmd>tab Git<cr>" },
      { "<leader>gl", "<cmd>tab Git log --follow -p %<cr>" },
      { "<leader>gL", "<cmd>tab Git log<cr>" },
      { "<leader>gb", "<cmd>tab Git blame<cr>" },
      { "<leader>gd", "<cmd>tab Git diff %<cr>" },
      { "<leader>gD", "<cmd>tab Git diff<cr>" },
      { "<leader>gP", '<cmd>Git push<cr>' },
      { "<leader>gp", '<cmd>Git pull --rebase<cr>' },
    },
  },

  {
    "lewis6991/gitsigns.nvim",
    opts = {
      numhl = true,
      signcolumn = false,
      on_attach = function(bufnr)
        local gitsigns = require("gitsigns")

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        map("n", "]c", function()
          if vim.wo.diff then vim.cmd.normal({ "]c", bang = true }) else gitsigns.nav_hunk("next") end
        end)
        map("n", "[c", function()
          if vim.wo.diff then vim.cmd.normal({ "[c", bang = true }) else gitsigns.nav_hunk("prev") end
        end)

        map("n", "ghs", gitsigns.stage_hunk)
        map("n", "ghu", gitsigns.reset_hunk)
        map("v", "ghs", function() gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end)
        map("v", "ghu", function() gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end)
        map("n", "ghS", gitsigns.stage_buffer)
        map("n", "ghU", gitsigns.reset_buffer)
        map("n", "ghp", gitsigns.preview_hunk_inline)
        map("n", "ghd", gitsigns.diffthis)
        map("n", "ghD", function() gitsigns.diffthis("~") end)

        map({ "o", "x" }, "ih", gitsigns.select_hunk)
      end,
    },
  }
}
