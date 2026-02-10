if vim.fn.has("unix") == 1 and vim.fn.has("macunix") == 0 then
  -- alleen op Linux (dus niet op macOS)
  return {
    {
      "ojroques/nvim-osc52",
      config = function()
        require("osc52").setup()
        vim.keymap.set("n", "<leader>y", require("osc52").copy_operator, { expr = true })
        vim.keymap.set("n", "<leader>Y", "<leader>y_", { remap = true })
        vim.keymap.set("v", "<leader>y", require("osc52").copy_visual)
      end,
    },
  }
end
