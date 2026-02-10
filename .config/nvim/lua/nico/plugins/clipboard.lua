-- Linux over SSH -> macOS clipboard via OSC52
-- Op macOS zelf doen we niks (native clipboard).

if vim.fn.has("unix") == 1 and vim.fn.has("macunix") == 0 then
  return {
    {
      "ojroques/nvim-osc52",
      config = function()
        local osc52 = require("osc52")

        osc52.setup({
          max_length = 0,
          silent = true,
          trim = false,
        })

        local function copy(lines, _)
          -- Neovim geeft {lines}; osc52 wil string
          osc52.copy(table.concat(lines, "\n"))
        end

        local function paste()
          -- “paste via osc52” kan niet echt; pak gewoon unnamed register
          local content = vim.fn.getreg('"')
          return vim.split(content, "\n"), vim.fn.getregtype('"')
        end

        vim.g.clipboard = {
          name = "osc52",
          copy = { ["+"] = copy, ["*"] = copy },
          paste = { ["+"] = paste, ["*"] = paste },
        }

        -- Optioneel: behoud je leader mappings
        vim.keymap.set("n", "<leader>y", osc52.copy_operator, { expr = true })
        vim.keymap.set("n", "<leader>Y", "<leader>y_", { remap = true })
        vim.keymap.set("v", "<leader>y", osc52.copy_visual)
      end,
    },
  }
end

return {}
