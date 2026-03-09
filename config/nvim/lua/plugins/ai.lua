return {
  {
    "supermaven-inc/supermaven-nvim",
    event = "InsertEnter",
    cmd = {
      "SupermavenUseFree",
      "SupermavenUsePro",
    },
    opts = {
      keymaps = {
        accept_suggestion = nil,
      },
      -- disable_inline_completion = true,
      ignore_filetypes = { "bigfile", "snacks_input", "snacks_notif" },
    },
  },
}
