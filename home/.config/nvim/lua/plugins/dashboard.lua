local alpha = require("alpha")
local dashboard = require("alpha.themes.dashboard")

dashboard.section.header.val = {
  "    ███╗   ██╗ ██████╗ ██╗  ██╗██╗",
  "    ████╗  ██║██╔═══██╗██║ ██╔╝██║",
  "    ██╔██╗ ██║██║   ██║█████╔╝ ██║",
  "    ██║╚██╗██║██║   ██║██╔═██╗ ██║",
  "    ██║ ╚████║╚██████╔╝██║  ██╗██║",
  "    ╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝╚═╝",
  "",
  "  N E O V I M   •   C O O L N I G H T",
}

dashboard.section.buttons.val = {
  dashboard.button("f", "  󰈞  Find file", "<cmd>FzfLua files<CR>"),
  dashboard.button("g", "  󰊄  Find text", "<cmd>FzfLua live_grep<CR>"),
  dashboard.button("e", "  󰙅  File tree", "<cmd>NvimTreeToggle<CR>"),
  dashboard.button("r", "  󰋚  Recent files", "<cmd>FzfLua oldfiles<CR>"),
  dashboard.button("q", "  󰅚  Quit", "<cmd>qa<CR>"),
}

dashboard.section.footer.val = {
  "NOKI EDITION",
  "󰉋  " .. vim.fn.fnamemodify(vim.fn.getcwd(), ":~"),
}

vim.api.nvim_set_hl(0, "AlphaHeader", {
  fg = "#24EAF7",
  bold = false,
})

vim.api.nvim_set_hl(0, "AlphaButtons", {
  fg = "#CBE0F0",
})

vim.api.nvim_set_hl(0, "AlphaShortcut", {
  fg = "#A277FF",
  bold = true,
})

vim.api.nvim_set_hl(0, "AlphaFooter", {
  fg = "#627E97",
  italic = true,
})

dashboard.section.header.opts.hl = "AlphaHeader"
dashboard.section.header.opts.position = "center"
dashboard.section.header.opts.margin = 3

dashboard.section.footer.opts.hl = "AlphaFooter"

for _, button in ipairs(dashboard.section.buttons.val) do
  button.opts.hl = "AlphaButtons"
  button.opts.hl_shortcut = "AlphaShortcut"
  button.opts.width = 40
  button.opts.cursor = 3
end

alpha.setup(dashboard.config)
