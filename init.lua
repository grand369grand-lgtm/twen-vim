-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Load Twen Chat module directly after UI is ready
-- We use VimEnter autocmd to ensure everything is initialized
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    -- Small delay to ensure all LazyVim plugins are loaded first
    vim.defer_fn(function()
      local ok, chat = pcall(require, "twen.chat")
      if ok then
        chat.setup()
      else
        vim.notify(
          "Twen Chat: Failed to load - " .. tostring(select(2, pcall(require, "twen.chat"))),
          vim.log.levels.WARN
        )
      end
    end, 100)
  end,
})
