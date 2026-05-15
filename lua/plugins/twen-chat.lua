-- Twen Chat Plugin - AI Chat Interface for Twen Vim
-- :Chat   - Open chat window
-- :ChatSet - Configure AI provider
--
-- This loads the local twen.chat module directly (not as a lazy plugin)
return {
  {
    "LazyVim/LazyVim",
    opts = {},
  },
  init = function()
    -- Load twen.chat module on startup
    local ok, chat = pcall(require, "twen.chat")
    if ok then
      chat.setup()
    end
  end,
}
