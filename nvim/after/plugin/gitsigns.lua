require("gitsigns").setup {
  signs                             = {
    add          = { hl = "GitSignsAdd", text = "▎", numhl = "GitSignsAddNr", linehl = "GitSignsAddLn" },
    change       = { hl = "GitSignsChange", text = "▎", numhl = "GitSignsChangeNr", linehl = "GitSignsChangeLn" },
    delete       = { hl = "GitSignsDelete", text = "▎", numhl = "GitSignsDeleteNr", linehl = "GitSignsDeleteLn" },
    topdelete    = { hl = "GitSignsDelete", text = "▎", numhl = "GitSignsDeleteNr", linehl = "GitSignsDeleteLn" },
    changedelete = { hl = "GitSignsChange", text = "▎", numhl = "GitSignsChangeNr", linehl = "GitSignsChangeLn" },
  },
  signcolumn                        = true, -- Toggle with `:Gitsigns toggle_signs`
  numhl                             = true, -- Toggle with `:Gitsigns toggle_numhl`
  linehl                            = false, -- Toggle with `:Gitsigns toggle_linehl`
  word_diff                         = false, -- Toggle with `:Gitsigns toggle_word_diff`
  keymaps                           = {
    noremap = true,
    ["n ]c"] = { expr = true, "&diff ? ']c' : '<cmd>lua require\"gitsigns.actions\".next_hunk()<CR>'" },
    ["n [c"] = { expr = true, "&diff ? '[c' : '<cmd>lua require\"gitsigns.actions\".prev_hunk()<CR>'" },
  },
  attach_to_untracked               = true,
  current_line_blame                = true, -- Toggle with `:Gitsigns toggle_current_line_blame`
  current_line_blame_opts           = {
    virt_text = true,
    virt_text_pos = "right_align", -- "eol" | "overlay" | "right_align"
    delay = 600,
  },
  current_line_blame_formatter_opts = {
    relative_time = false
  },
  sign_priority                     = 6,
  update_debounce                   = 100,
  status_formatter                  = nil, -- Use default
  max_file_length                   = 40000,
  yadm                              = {
    enable = false
  },
}
