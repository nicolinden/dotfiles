local fzf = require("fzf-lua")

fzf.setup()

vim.keymap.set("n", "<leader>ff", fzf.files, {
  desc = "Find files",
})

vim.keymap.set("n", "<leader>fg", fzf.live_grep, {
  desc = "Find text in project",
})

vim.keymap.set("n", "<leader>fb", fzf.buffers, {
  desc = "Find open buffers",
})
