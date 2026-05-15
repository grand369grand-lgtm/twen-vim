# Twen Vim

A [LazyVim](https://github.com/LazyVim/LazyVim) based Neovim setup with built-in AI Chat.
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

## 💬 Twen Chat - AI Chat Interface

Twen Vim includes a built-in AI chat interface with multi-provider support.

### Commands

| Command | Description |
|---------|-------------|
| `:Chat` | Open chat window |
| `:ChatSet` | Configure AI provider settings |

### Chat Keybindings

| Key | Action |
|-----|--------|
| `Enter` | Send message |
| `Esc` | Close chat |
| `Ctrl+s` | Save settings (in :ChatSet) |

### ChatSet Provider Selection

| Key | Action |
|-----|--------|
| `↑` / `↓` | Navigate providers |
| `Enter` / `x` | Select provider |
| `Ctrl+s` | Save and exit |
| `Esc` | Exit without saving |

### Supported AI Providers

| Provider | Model | API Key Env Var |
|----------|-------|-----------------|
| NVIDIA NIM | Llama 3.1 405B | `NVIDIA_NIM_API_KEY` |
| Claude (Anthropic) | Claude Sonnet 4 | `ANTHROPIC_API_KEY` |
| ChatGPT (OpenAI) | GPT-4o | `OPENAI_API_KEY` |
| Gemini (Google) | Gemini Pro | `GEMINI_API_KEY` |
| Groq | Llama 3.1 70B | `GROQ_API_KEY` |
| Mistral AI | Mistral Large | `MISTRAL_API_KEY` |
| DeepSeek | DeepSeek Chat | `DEEPSEEK_API_KEY` |
| Ollama (Local) | Llama 3.1 | No key needed |
| Together AI | Llama 3.1 405B Turbo | `TOGETHER_API_KEY` |
| Perplexity AI | Sonar Large | `PERPLEXITY_API_KEY` |

### Setup Example

```sh
# Set your API key (e.g., for ChatGPT)
export OPENAI_API_KEY="sk-your-key-here"

# Open Neovim and configure
nvim
:ChatSet    # Select your provider
:Chat       # Start chatting!
```

## ⚡️ Requirements

- Neovim >= **0.11.2** (built with **LuaJIT**)
- Git >= **2.19.0**
- `curl` (for AI chat API calls)
- a [Nerd Font](https://www.nerdfonts.com/) _(optional)_
- a **C** compiler for `nvim-treesitter`

## 📂 File Structure

```
~/.config/nvim
├── init.lua                  -- Entry point
├── lua
│   ├── config
│   │   ├── autocmds.lua      -- Custom autocommands
│   │   ├── keymaps.lua       -- Custom keymaps
│   │   ├── lazy.lua          -- LazyVim plugin setup
│   │   └── options.lua       -- Custom options
│   ├── plugins
│   │   ├── twen-chat.lua     -- Chat plugin spec
│   │   └── twen-dashboard.lua -- Dashboard with Twen Vim banner
│   └── twen
│       └── chat
│           └── init.lua      -- Chat core module
├── install.sh                -- CLI installer
└── stylua.toml
```

## 📄 License

Apache License 2.0
