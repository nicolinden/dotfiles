vim.pack.add({
  "https://github.com/folke/tokyonight.nvim",
  "https://github.com/nvim-tree/nvim-tree.lua",
  "https://github.com/nvim-tree/nvim-web-devicons",
  "https://github.com/ibhagwan/fzf-lua",
}, {
  confirm = false,
})

require("plugins.colorscheme")
require("plugins.filetree")
require("plugins.fuzzy")
