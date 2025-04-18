return {
  {
    "tpope/vim-fugitive",
    lazy = false,
    keys = {
      { "<leader>g=", "<cmd>tab Git<cr>"},
      { "<leader>gl", "<cmd>tab Git log --follow -p %<cr>"},
      { "<leader>gL", "<cmd>tab Git log<cr>"},
      { "<leader>gb", "<cmd>tab Git blame<cr>"},
      { "<leader>gd", "<cmd>tab Git diff %<cr>"},
      { "<leader>gD", "<cmd>tab Git diff<cr>"},
      { "<leader>gP", '<cmd>Git push<cr>'},
      { "<leader>gp", '<cmd>Git pull --rebase<cr>'},
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
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gitsigns.nav_hunk("next")
          end
        end)
        map("n", "[c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gitsigns.nav_hunk("prev")
          end
        end)

        -- Actions
        map("n", "<leader>hs", gitsigns.stage_hunk)
        map("n", "<leader>hu", gitsigns.reset_hunk)

        map("v", "<leader>hs", function()
          gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end)
        map("v", "<leader>hu", function()
          gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end)

        map("n", "<leader>hS", gitsigns.stage_buffer)
        map("n", "<leader>hU", gitsigns.reset_buffer)
        map("n", "<leader>hp", gitsigns.preview_hunk_inline)

        map("n", "<leader>hb", function()
          gitsigns.blame_line({ full = true })
        end)

        map("n", "<leader>hd", gitsigns.diffthis)

        map("n", "<leader>hD", function()
          gitsigns.diffthis("~")
        end)

        map("n", "<leader>hQ", function()
          gitsigns.setqflist("all")
        end)
        map("n", "<leader>hq", gitsigns.setqflist)

        -- Text object
        map({ "o", "x" }, "ih", gitsigns.select_hunk)
      end,
    },
  }
}
