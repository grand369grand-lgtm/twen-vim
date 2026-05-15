--- Twen Chat - AI Chat Interface for Twen Vim
--- Provides :Chat command to open chat window
--- Provides :ChatSet command to configure AI providers
--- Keymaps: <leader>ci = open chat, <leader>cs = chat settings

local M = {}

-- State
M.state = {
  buf = nil,
  win = nil,
  input_buf = nil,
  input_win = nil,
  history = {},
  provider = nil,
  providers = {},
  config = {},
  settings_win = nil,
  settings_buf = nil,
}

--- Load provider definitions
function M.load_providers()
  M.state.providers = {
    {
      id = "nvidia-nim",
      name = "NVIDIA NIM",
      api_url = "https://integrate.api.nvidia.com/v1/chat/completions",
      api_key_env = "NVIDIA_NIM_API_KEY",
      model = "meta/llama-3.1-405b-instruct",
      description = "NVIDIA NIM - Llama 3.1 405B",
      type = "openai",
    },
    {
      id = "claude",
      name = "Claude (Anthropic)",
      api_url = "https://api.anthropic.com/v1/messages",
      api_key_env = "ANTHROPIC_API_KEY",
      model = "claude-sonnet-4-20250514",
      description = "Claude Sonnet 4 by Anthropic",
      type = "anthropic",
    },
    {
      id = "chatgpt",
      name = "ChatGPT (OpenAI)",
      api_url = "https://api.openai.com/v1/chat/completions",
      api_key_env = "OPENAI_API_KEY",
      model = "gpt-4o",
      description = "ChatGPT GPT-4o by OpenAI",
      type = "openai",
    },
    {
      id = "gemini",
      name = "Gemini (Google)",
      api_url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent",
      api_key_env = "GEMINI_API_KEY",
      model = "gemini-pro",
      description = "Gemini Pro by Google DeepMind",
      type = "gemini",
    },
    {
      id = "groq",
      name = "Groq",
      api_url = "https://api.groq.com/openai/v1/chat/completions",
      api_key_env = "GROQ_API_KEY",
      model = "llama-3.1-70b-versatile",
      description = "Groq - Ultra-fast LLM inference",
      type = "openai",
    },
    {
      id = "mistral",
      name = "Mistral AI",
      api_url = "https://api.mistral.ai/v1/chat/completions",
      api_key_env = "MISTRAL_API_KEY",
      model = "mistral-large-latest",
      description = "Mistral Large by Mistral AI",
      type = "openai",
    },
    {
      id = "deepseek",
      name = "DeepSeek",
      api_url = "https://api.deepseek.com/v1/chat/completions",
      api_key_env = "DEEPSEEK_API_KEY",
      model = "deepseek-chat",
      description = "DeepSeek Chat - Coding assistant",
      type = "openai",
    },
    {
      id = "ollama",
      name = "Ollama (Local)",
      api_url = "http://localhost:11434/api/chat",
      api_key_env = "",
      model = "llama3.1",
      description = "Ollama - Run locally (no key needed)",
      type = "ollama",
    },
    {
      id = "together",
      name = "Together AI",
      api_url = "https://api.together.xyz/v1/chat/completions",
      api_key_env = "TOGETHER_API_KEY",
      model = "meta-llama/Meta-Llama-3.1-405B-Instruct-Turbo",
      description = "Together AI - Open source hosting",
      type = "openai",
    },
    {
      id = "perplexity",
      name = "Perplexity AI",
      api_url = "https://api.perplexity.ai/chat/completions",
      api_key_env = "PERPLEXITY_API_KEY",
      model = "llama-3.1-sonar-large-128k-online",
      description = "Perplexity Sonar - Web-connected AI",
      type = "openai",
    },
  }
end

--- Load saved config
function M.load_config()
  local config_path = vim.fn.stdpath("data") .. "/twen-chat-config.json"
  local f = io.open(config_path, "r")
  if f then
    local content = f:read("*a")
    f:close()
    local ok, config = pcall(vim.fn.json_decode, content)
    if ok and config then
      M.state.config = config
      M.state.provider = config.provider or nil
    end
  end
  M.load_providers()
end

--- Save config
function M.save_config()
  local config_path = vim.fn.stdpath("data") .. "/twen-chat-config.json"
  local config = {
    provider = M.state.provider,
  }
  local f = io.open(config_path, "w")
  if f then
    f:write(vim.fn.json_encode(config))
    f:close()
  end
end

--- Get current provider
function M.get_provider()
  if not M.state.provider then
    return nil
  end
  for _, p in ipairs(M.state.providers) do
    if p.id == M.state.provider then
      return vim.deepcopy(p)
    end
  end
  return nil
end

--- Format timestamp
local function timestamp()
  return os.date("%H:%M")
end

--- Add message to chat history
function M.add_message(role, content)
  local msg = {
    role = role,
    content = content,
    time = timestamp(),
  }
  table.insert(M.state.history, msg)
  M.render_history()
end

--- Render chat history in the chat buffer
function M.render_history()
  if not M.state.buf or not vim.api.nvim_buf_is_valid(M.state.buf) then
    return
  end

  local lines = {}
  table.insert(lines, "  ╔══════════════════════════════════════════════════════╗")
  table.insert(lines, "  ║            T W E N   C H A T                        ║")

  local provider = M.get_provider()
  if provider then
    local pad = math.max(0, 43 - #provider.name)
    table.insert(lines, "  ║  Provider: " .. provider.name .. string.rep(" ", pad) .. "║")
  else
    table.insert(lines, "  ║  Provider: Not set (run :ChatSet)                   ║")
  end

  table.insert(lines, "  ╚══════════════════════════════════════════════════════╝")
  table.insert(lines, "")

  if #M.state.history == 0 then
    table.insert(lines, "  Welcome to Twen Chat!")
    table.insert(lines, "  Type your message below and press <Enter> to send.")
    table.insert(lines, "  Run :ChatSet to configure your AI provider.")
    table.insert(lines, "")
    table.insert(lines, "  Available providers:")
    for _, p in ipairs(M.state.providers) do
      table.insert(lines, "    * " .. p.name .. " - " .. p.description)
    end
    table.insert(lines, "")
  else
    for _, msg in ipairs(M.state.history) do
      if msg.role == "user" then
        table.insert(lines, "  +-- You [" .. msg.time .. "] ---------------------------------")
        for _, line in ipairs(vim.split(msg.content, "\n")) do
          table.insert(lines, "  | " .. line)
        end
        table.insert(lines, "  +------------------------------------------------")
      elseif msg.role == "assistant" then
        table.insert(lines, "  +-- AI [" .. msg.time .. "] ----------------------------------")
        for _, line in ipairs(vim.split(msg.content, "\n")) do
          table.insert(lines, "  | " .. line)
        end
        table.insert(lines, "  +------------------------------------------------")
      elseif msg.role == "system" then
        table.insert(lines, "  >> " .. msg.content)
      end
      table.insert(lines, "")
    end
  end

  vim.bo[M.state.buf].modifiable = true
  vim.api.nvim_buf_set_lines(M.state.buf, 0, -1, false, lines)
  vim.bo[M.state.buf].modifiable = false

  -- Auto scroll to bottom
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    pcall(vim.api.nvim_win_set_cursor, M.state.win, { #lines, 0 })
  end
end

--- Send message to AI provider
function M.send_message(message)
  M.add_message("user", message)

  local provider = M.get_provider()
  if not provider then
    M.add_message("system", "No provider configured. Run :ChatSet to select an AI provider.")
    return
  end

  -- Check for API key
  if provider.api_key_env ~= "" then
    local api_key = os.getenv(provider.api_key_env)
    if not api_key or api_key == "" then
      M.add_message(
        "system",
        "API key not found! Set env variable: " .. provider.api_key_env
      )
      return
    end
  end

  -- Build messages array for API (exclude system messages)
  local api_messages = {}
  for _, msg in ipairs(M.state.history) do
    if msg.role == "user" or msg.role == "assistant" then
      table.insert(api_messages, { role = msg.role, content = msg.content })
    end
  end

  M.add_message("system", "Sending to " .. provider.name .. " ...")
  -- Remove the "Sending..." system message from display history
  table.remove(M.state.history)

  -- Call AI provider asynchronously
  M.call_provider(provider, api_messages)
end

--- Call AI provider via curl
function M.call_provider(provider, messages)
  local request_body
  local api_url = provider.api_url
  local headers = { "Content-Type: application/json" }

  if provider.type == "anthropic" then
    request_body = vim.fn.json_encode({
      model = provider.model,
      max_tokens = 4096,
      messages = messages,
    })
    local api_key = os.getenv(provider.api_key_env) or ""
    table.insert(headers, "x-api-key: " .. api_key)
    table.insert(headers, "anthropic-version: 2023-06-01")
  elseif provider.type == "gemini" then
    local api_key = os.getenv(provider.api_key_env) or ""
    api_url = api_url .. "?key=" .. api_key
    local gemini_contents = {}
    for _, msg in ipairs(messages) do
      table.insert(gemini_contents, {
        role = msg.role == "assistant" and "model" or "user",
        parts = { { text = msg.content } },
      })
    end
    request_body = vim.fn.json_encode({ contents = gemini_contents })
  elseif provider.type == "ollama" then
    request_body = vim.fn.json_encode({
      model = provider.model,
      messages = messages,
      stream = false,
    })
  else
    -- OpenAI-compatible APIs
    request_body = vim.fn.json_encode({
      model = provider.model,
      messages = messages,
      max_tokens = 4096,
    })
    if provider.api_key_env ~= "" then
      local api_key = os.getenv(provider.api_key_env) or ""
      table.insert(headers, "Authorization: Bearer " .. api_key)
    end
  end

  -- Build curl command
  local cmd = { "curl", "-s", "--max-time", "60", "-X", "POST", api_url }
  for _, h in ipairs(headers) do
    table.insert(cmd, "-H")
    table.insert(cmd, h)
  end
  table.insert(cmd, "-d")
  table.insert(cmd, request_body)

  local provider_name = provider.name
  local provider_type = provider.type

  vim.system(cmd, { text = true }, function(result)
    local response_text = ""

    if result.code ~= 0 then
      response_text = "Error: Failed to connect to " .. provider_name .. " (exit code: " .. result.code .. ")"
    else
      local ok, data = pcall(vim.fn.json_decode, result.stdout or "")
      if not ok or not data then
        response_text = "Error: Invalid response from " .. provider_name
      elseif data.error then
        local err_msg = type(data.error) == "table" and (data.error.message or vim.inspect(data.error))
          or tostring(data.error)
        response_text = "Error from " .. provider_name .. ": " .. err_msg
      elseif provider_type == "anthropic" then
        if data.content and data.content[1] and data.content[1].text then
          response_text = data.content[1].text
        else
          response_text = "No response from " .. provider_name
        end
      elseif provider_type == "gemini" then
        if
          data.candidates
          and data.candidates[1]
          and data.candidates[1].content
          and data.candidates[1].content.parts
          and data.candidates[1].content.parts[1]
        then
          response_text = data.candidates[1].content.parts[1].text or "No response"
        else
          response_text = "No response from " .. provider_name
        end
      elseif provider_type == "ollama" then
        if data.message and data.message.content then
          response_text = data.message.content
        else
          response_text = "No response from " .. provider_name
        end
      else
        -- OpenAI-compatible response
        if data.choices and data.choices[1] and data.choices[1].message and data.choices[1].message.content then
          response_text = data.choices[1].message.content
        else
          response_text = "No response from " .. provider_name
        end
      end
    end

    vim.schedule(function()
      M.add_message("assistant", response_text)
    end)
  end)
end

--- Close chat window
function M.close_chat()
  if M.state.input_win and vim.api.nvim_win_is_valid(M.state.input_win) then
    pcall(vim.api.nvim_win_close, M.state.input_win, true)
  end
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    pcall(vim.api.nvim_win_close, M.state.win, true)
  end
  M.state.win = nil
  M.state.buf = nil
  M.state.input_win = nil
  M.state.input_buf = nil
end

--- Open chat window
function M.open_chat()
  -- If already open, focus it
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    pcall(vim.api.nvim_set_current_win, M.state.input_win)
    return
  end

  -- Make sure providers are loaded
  if #M.state.providers == 0 then
    M.load_config()
  end

  local width = math.max(40, math.floor(vim.o.columns * 0.8))
  local height = math.max(10, math.floor(vim.o.lines * 0.7))
  local chat_height = math.max(5, height - 5)
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  -- Create chat history buffer
  M.state.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[M.state.buf].bufhidden = "hide"
  vim.bo[M.state.buf].buftype = "nofile"
  vim.bo[M.state.buf].modifiable = false
  vim.bo[M.state.buf].filetype = "twen-chat"

  -- Create chat history window
  M.state.win = vim.api.nvim_open_win(M.state.buf, true, {
    relative = "editor",
    width = width,
    height = chat_height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
    title = " Twen Chat ",
    title_pos = "center",
  })
  vim.wo[M.state.win].wrap = true
  vim.wo[M.state.win].cursorline = false
  vim.wo[M.state.win].number = false
  vim.wo[M.state.win].relativenumber = false
  vim.wo[M.state.win].signcolumn = "no"

  -- Create input buffer
  M.state.input_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[M.state.input_buf].bufhidden = "hide"
  vim.bo[M.state.input_buf].buftype = "nofile"
  vim.bo[M.state.input_buf].filetype = "twen-chat-input"

  -- Create input window
  M.state.input_win = vim.api.nvim_open_win(M.state.input_buf, true, {
    relative = "editor",
    width = width,
    height = 3,
    col = col,
    row = row + chat_height + 2,
    style = "minimal",
    border = "rounded",
    title = " Message (Enter=send | Esc=close) ",
    title_pos = "center",
  })
  vim.wo[M.state.input_win].wrap = true
  vim.wo[M.state.input_win].number = false
  vim.wo[M.state.input_win].relativenumber = false
  vim.wo[M.state.input_win].signcolumn = "no"

  -- Set up keymaps for input buffer
  local function send_input()
    local lines = vim.api.nvim_buf_get_lines(M.state.input_buf, 0, -1, false)
    local message = table.concat(lines, "\n"):match("^%s*(.-)%s*$")
    if message ~= "" then
      -- Clear input
      vim.api.nvim_buf_set_lines(M.state.input_buf, 0, -1, false, {})
      M.send_message(message)
    end
  end

  -- Keymaps for input buffer (buffer-local, won't affect other buffers)
  vim.keymap.set("n", "<CR>", send_input, { buffer = M.state.input_buf, nowait = true })
  vim.keymap.set("i", "<CR>", function()
    send_input()
  end, { buffer = M.state.input_buf, nowait = true })
  vim.keymap.set("i", "<C-CR>", function()
    -- Insert actual newline
    vim.api.nvim_put({ "" }, "l", false, true)
  end, { buffer = M.state.input_buf })
  vim.keymap.set({ "n", "i" }, "<Esc>", function()
    M.close_chat()
  end, { buffer = M.state.input_buf })

  -- Esc on chat history window to close
  vim.keymap.set("n", "<Esc>", function()
    M.close_chat()
  end, { buffer = M.state.buf })

  -- Close on buffer delete
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = M.state.buf,
    callback = function()
      M.close_chat()
    end,
  })

  -- Render initial history
  M.render_history()

  -- Start in insert mode in input window
  vim.api.nvim_set_current_win(M.state.input_win)
  vim.cmd("startinsert")
end

--- Open provider settings UI
function M.open_settings()
  -- Load providers if not loaded
  if #M.state.providers == 0 then
    M.load_config()
  end

  local width = math.min(70, vim.o.columns - 4)
  local height = math.min(#M.state.providers * 5 + 8, vim.o.lines - 4)
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  M.state.settings_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[M.state.settings_buf].bufhidden = "wipe"
  vim.bo[M.state.settings_buf].buftype = "nofile"
  vim.bo[M.state.settings_buf].filetype = "twen-chat-settings"
  vim.bo[M.state.settings_buf].modifiable = false

  M.state.settings_win = vim.api.nvim_open_win(M.state.settings_buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
    title = " Twen Chat - Provider Settings ",
    title_pos = "center",
  })
  vim.wo[M.state.settings_win].number = false
  vim.wo[M.state.settings_win].relativenumber = false
  vim.wo[M.state.settings_win].cursorline = true
  vim.wo[M.state.settings_win].signcolumn = "no"

  -- Render settings content
  M.render_settings()

  -- Move cursor to first provider
  pcall(vim.api.nvim_win_set_cursor, M.state.settings_win, { 4, 0 })

  -- Keymaps for settings
  local function select_provider()
    local cursor = vim.api.nvim_win_get_cursor(M.state.settings_win)
    local line_num = cursor[1]
    for i, p in ipairs(M.state.providers) do
      local target_line = 3 + (i - 1) * 5 + 1
      if line_num >= target_line and line_num < target_line + 4 then
        M.state.provider = p.id
        vim.notify("Provider set to: " .. p.name, vim.log.levels.INFO)
        M.render_settings()
        break
      end
    end
  end

  vim.keymap.set("n", "<CR>", select_provider, { buffer = M.state.settings_buf, nowait = true })
  vim.keymap.set("n", "x", select_provider, { buffer = M.state.settings_buf, nowait = true })
  vim.keymap.set("n", "<Esc>", function()
    vim.api.nvim_win_close(M.state.settings_win, true)
  end, { buffer = M.state.settings_buf, nowait = true })
  vim.keymap.set("n", "<C-s>", function()
    M.save_config()
    vim.notify("Twen Chat settings saved!", vim.log.levels.INFO)
    vim.api.nvim_win_close(M.state.settings_win, true)
  end, { buffer = M.state.settings_buf, nowait = true })
end

--- Render settings content
function M.render_settings()
  local buf = M.state.settings_buf
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local current = M.state.provider
  local lines = {}
  table.insert(lines, "  Select an AI Provider:")
  table.insert(lines, "  ----------------------------------------------------")
  table.insert(lines, "")

  for i, p in ipairs(M.state.providers) do
    local marker = (current == p.id) and " [x] " or " [ ] "
    local line = marker .. i .. ". " .. p.name
    table.insert(lines, line)
    table.insert(lines, "      " .. p.description)
    table.insert(lines, "      Model: " .. p.model)
    if p.api_key_env ~= "" then
      local key_set = (os.getenv(p.api_key_env) or "") ~= ""
      local key_status = key_set and "[OK] Key set" or "[!!] Key not set"
      table.insert(lines, "      Key: " .. p.api_key_env .. " (" .. key_status .. ")")
    else
      table.insert(lines, "      Key: Not required (local)")
    end
    table.insert(lines, "")
  end

  table.insert(lines, "  ----------------------------------------------------")
  table.insert(lines, "  Up/Down: Navigate  |  Enter/x: Select  |  Ctrl+s: Save  |  Esc: Exit")

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
end

--- Setup function - called on Neovim startup
function M.setup()
  -- Load config and providers
  M.load_config()

  -- Create :Chat command
  vim.api.nvim_create_user_command("Chat", function()
    M.open_chat()
  end, { desc = "Open Twen Chat - AI Chat Interface" })

  -- Create :ChatSet command
  vim.api.nvim_create_user_command("ChatSet", function()
    M.open_settings()
  end, { desc = "Configure Twen Chat AI Provider" })

  -- Keymaps: <leader>ci = open chat, <leader>cs = chat settings
  vim.keymap.set("n", "<leader>ci", function()
    M.open_chat()
  end, { desc = "Twen Chat", silent = true })

  vim.keymap.set("n", "<leader>cs", function()
    M.open_settings()
  end, { desc = "Twen Chat Settings", silent = true })
end

return M
