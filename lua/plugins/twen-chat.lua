-- Twen Chat Plugin - AI Chat Interface for Twen Vim
-- :Chat   - Open chat window
-- :ChatSet - Configure AI provider
return {
  {
    dir = vim.fn.stdpath("config") .. "/lua/twen",
    name = "twen-chat",
    lazy = false,
    config = function()
      require("twen.chat").setup()
    end,
  },
}
