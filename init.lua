-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Load Twen Chat module directly (not as a lazy.nvim plugin)
-- This ensures :Chat and :ChatSet commands are available after startup
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    local ok, chat = pcall(require, "twen.chat")
    if ok then
      chat.setup()
    else
      vim.notify("Twen Chat: Failed to load module - " .. (select(2, pcall(require, "twen.chat")) or "unknown error"), vim.log.levels.WARN)
    end
  end,
})
