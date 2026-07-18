vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt

-- Interface
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.scrolloff = 4
opt.wrap = false

-- Indentation
opt.expandtab = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2

-- Searching
opt.ignorecase = true
opt.smartcase = true

-- Editing
opt.clipboard = "unnamedplus"
opt.splitright = true
opt.splitbelow = true
opt.confirm = true
opt.inccommand = "split"
