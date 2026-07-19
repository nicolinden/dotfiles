require("config.options")
require("config.keymaps")

-- VS Code provides its own interface, file tree and search.
if not vim.g.vscode then
  require("plugins")
end
