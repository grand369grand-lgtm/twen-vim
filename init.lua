-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Load Twen Chat module (ensure :Chat and :ChatSet commands are available)
-- This is a fallback - the plugin spec in lua/plugins/twen-chat.lua also loads it
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    -- Only setup if commands don't already exist (avoid double setup)
    if not vim.api.nvim_get_commands({})["Chat"] then
      local ok, chat = pcall(require, "twen.chat")
      if ok then
        chat.setup()
      end
    end
  end,
})
