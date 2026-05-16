-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Twen Vim custom options
vim.g.autoformat = true -- enable autoformat on save
vim.opt.swapfile = false -- disable swap files
vim.opt.undofile = true -- persistent undo
vim.opt.scrolloff = 8 -- lines of context
vim.opt.sidescrolloff = 8 -- columns of context
vim.opt.updatetime = 250 -- faster cursor hold events
