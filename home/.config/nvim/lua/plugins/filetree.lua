-- Replace Neovim's built-in file explorer
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("nvim-tree").setup({
  view = {
    width = 32,
  },
  renderer = {
    indent_markers = {
      enable = true,
    },
  },
  filters = {
    custom = { ".DS_Store" },
  },
})

vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", {
  desc = "Toggle file tree",
})
