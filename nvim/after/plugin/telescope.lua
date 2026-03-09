require("telescope").setup {
  defaults = {
    sorting_strategy = "ascending",
    mappings = {
      -- restore default behavior
      i = {
        ["<C-u>"] = false,
        ["<C-d>"] = false,
      },
    },
  },
  pickers = {
    buffers = {
      ignore_current_buffer = true,
      sort_mru = true
    }
  },
}
