-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Better window navigation
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to left window", remap = true })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to lower window", remap = true })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to upper window", remap = true })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to right window", remap = true })

-- Resize windows
vim.keymap.set("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
vim.keymap.set("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
vim.keymap.set("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
vim.keymap.set("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })

-- Clear search highlighting
-- Note: Esc in chat buffers is handled by the twen.chat module's buffer-local keymaps
-- This global mapping will not fire for chat buffers since buffer-local takes precedence
vim.keymap.set("n", "<Esc>", function()
  -- Don't override Esc in twen-chat buffers (they have their own buffer-local mappings)
  local ft = vim.bo.filetype
  if ft == "twen-chat" or ft == "twen-chat-input" or ft == "twen-chat-settings" then
    return
  end
  vim.cmd("noh")
end, { desc = "Clear search highlighting" })
