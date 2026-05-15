# Twen Vim

A [LazyVim](https://github.com/LazyVim/LazyVim) based Neovim setup.
Refer to the [documentation](https://lazyvim.github.io) to get started.

## 🚀 Quick Install

### One-liner (Recommended)

```sh
curl -sL https://raw.githubusercontent.com/grand369grand-lgtm/twen-vim/main/install.sh | bash
```

### Manual Install

```sh
# Backup existing config
mv ~/.config/nvim ~/.config/nvim.bak
mv ~/.local/share/nvim ~/.local/share/nvim.bak

# Clone Twen Vim
git clone https://github.com/grand369grand-lgtm/twen-vim.git ~/.config/nvim

# Remove .git so you can add it to your own repo
rm -rf ~/.config/nvim/.git

# Start Neovim
nvim
```

### Try it with Docker

```sh
docker run -w /root -it --rm alpine:edge sh -uelic '
  apk add git lazygit fzf curl neovim ripgrep alpine-sdk --update
  git clone https://github.com/grand369grand-lgtm/twen-vim.git ~/.config/nvim
  cd ~/.config/nvim
  nvim
'
```

### CLI Options

```sh
# Install
bash ~/.config/nvim/install.sh

# Update Twen Vim & plugins
bash ~/.config/nvim/install.sh --update

# Uninstall
bash ~/.config/nvim/install.sh --uninstall

# Help
bash ~/.config/nvim/install.sh --help
```

## ⚡️ Requirements

- Neovim >= **0.11.2** (built with **LuaJIT**)
- Git >= **2.19.0**
- a [Nerd Font](https://www.nerdfonts.com/) _(optional)_
- a **C** compiler for `nvim-treesitter`

## 📂 File Structure

```
~/.config/nvim
├── init.lua              -- Entry point
├── lua
│   ├── config
│   │   ├── autocmds.lua  -- Custom autocommands
│   │   ├── keymaps.lua   -- Custom keymaps
│   │   ├── lazy.lua      -- LazyVim plugin setup
│   │   └── options.lua   -- Custom options
│   └── plugins
│       └── *.lua         -- Plugin specs
├── install.sh            -- CLI installer
└── stylua.toml
```

## 📄 License

Apache License 2.0
