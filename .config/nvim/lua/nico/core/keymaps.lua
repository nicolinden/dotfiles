vim.g.mapleader = " "

local keymap = vim.keymap

keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })

keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

-- window management
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" }) -- split window vertically
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" }) -- split window horizontally
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" }) -- make split windows equal width & height
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" }) -- close current split window

keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" }) -- open new tab
keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" }) -- close current tab
keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" }) --  go to next tab
keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" }) --  go to previous tab
keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" }) --  move current buffer to new tab

-- Resize window
keymap.set("n", "<leader><C-k>", ":resize -5<CR>", { desc = "Resize window up" }) -- resize window up
keymap.set("n", "<leader><C-j>", ":resize +5<CR>", { desc = "Resize window down" }) -- resize window down
keymap.set("n", "<leader><C-h>", ":vertical resize -5<CR>", { desc = "Resize window left" }) -- resize window left
keymap.set("n", "<leader><C-l>", ":vertical resize +5<CR>", { desc = "Resize window right" }) -- resize window right
keymap.set("n", "<leader>sm", ":MaximizerToggle<CR>", { desc = "Toggle Maximizer" }) -- toggle maximizer

-- Normale modus: <leader>yy kopieert de huidige regel via OSC52
vim.keymap.set("n", "<leader>yy", function()
  require("osc52").copy(vim.api.nvim_get_current_line())
end, { desc = "Yank current line via OSC52" })

-- Visuele modus: <leader>y kopieert selectie via OSC52
vim.keymap.set("v", "<leader>y", function()
  require("osc52").copy(vim.fn.getreg('"'))
end, { desc = "Yank visual selection via OSC52" })
