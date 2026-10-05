local M = {}

function M.apply()
  local path = vim.fn.stdpath("config") .. "/lua/matugen_palette.lua"
  -- dofile instead of require, so a changed palette is re-read every time
  local ok, palette = pcall(dofile, path)
  if not ok then
    vim.cmd.colorscheme("habamax") -- fallback until matugen has run
    return
  end

  -- Pick light/dark from how bright the background is
  local r = tonumber(palette.base00:sub(2, 3), 16)
  local g = tonumber(palette.base00:sub(4, 5), 16)
  local b = tonumber(palette.base00:sub(6, 7), 16)
  vim.o.background = (0.299 * r + 0.587 * g + 0.114 * b) > 128 and "light" or "dark"

  require("mini.base16").setup({ palette = palette })
  vim.g.colors_name = "matugen"
end

-- Called by setwall in every running Neovim
_G.MatugenReload = M.apply

return M
