-- Twen Chat Plugin - AI Chat Interface for Twen Vim
-- :Chat   - Open chat window
-- :ChatSet - Configure AI provider
--
-- This loads the local twen.chat module as a lazy.nvim plugin spec
return {
  {
    "twen-chat",
    lazy = false,
    priority = 1000,
    config = function()
      local ok, chat = pcall(require, "twen.chat")
      if ok then
        chat.setup()
      else
        vim.notify("Twen Chat: Failed to load module", vim.log.levels.ERROR)
      end
    end,
  },
}
