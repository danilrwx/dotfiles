vim.diagnostic.config({ virtual_text = { prefix = "🐗" }, signs = false })

vim.keymap.set("n", "<leader>D", "<cmd>Diagnostics<cr>", { silent = true })
