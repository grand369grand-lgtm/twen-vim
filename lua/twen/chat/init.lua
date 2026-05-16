--- Twen Chat - AI Chat Interface for Twen Vim
--- Provides :Chat command to open chat window
--- Provides :ChatSet command to configure AI providers
--- Keymaps: <leader>ci = open chat, <leader>cs = chat settings
---
--- In Chat window:
---   Enter       = Send message (in input box)
---   Ctrl+J      = Insert newline (for multiline messages)
---   Esc         = Close chat
---
--- In Settings window:
---   j/Down      = Move down
---   k/Up        = Move up
---   x/Enter     = Select provider
---   Ctrl+S      = Save and close
---   Esc/q       = Close without saving

local M = {}

-- ---------------------------------------------------------------------------
-- State
-- ---------------------------------------------------------------------------
M.state = {
  buf = nil,           -- chat history buffer
  win = nil,           -- chat history window
  input_buf = nil,     -- input buffer
  input_win = nil,     -- input window
  history = {},        -- chat messages {role, content, time}
  provider = nil,      -- selected provider id
  providers = {},      -- provider definitions
  config = {},         -- saved config table
  settings_win = nil,  -- settings window id
  settings_buf = nil,  -- settings buffer id
  pending_job = nil,   -- current curl job id (for cancellation)
}

-- ---------------------------------------------------------------------------
-- Provider definitions
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- Config persistence
-- ---------------------------------------------------------------------------
function M.load_config()
  local config_path = vim.fn.stdpath("data") .. "/twen-chat-config.json"
  M.load_providers()
  local f = io.open(config_path, "r")
  if f then
    local content = f:read("*a")
    f:close()
    local ok, config = pcall(vim.fn.json_decode, content)
    if ok and type(config) == "table" then
      M.state.config = config
      M.state.provider = config.provider or nil
    end
  end
end

function M.save_config()
  local config_path = vim.fn.stdpath("data") .. "/twen-chat-config.json"
  local config = { provider = M.state.provider }
  local ok, encoded = pcall(vim.fn.json_encode, config)
  if ok and encoded then
    local f = io.open(config_path, "w")
    if f then
      f:write(encoded)
      f:close()
    end
  end
end

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
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

local function timestamp()
  return os.date("%H:%M")
end

-- Check if vim.system is available (Neovim 0.10+)
local function has_vim_system()
  return type(vim.system) == "function"
end

-- ---------------------------------------------------------------------------
-- Chat history rendering
-- ---------------------------------------------------------------------------
function M.add_message(role, content)
  local msg = {
    role = role,
    content = content,
    time = timestamp(),
  }
  table.insert(M.state.history, msg)
  M.render_history()
end

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
    table.insert(lines, "  Press <Ctrl+J> for a new line (multiline input).")
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

  -- Auto-scroll to bottom
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    pcall(vim.api.nvim_win_set_cursor, M.state.win, { #lines, 0 })
  end
end

-- ---------------------------------------------------------------------------
-- AI provider API call
-- ---------------------------------------------------------------------------
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
        "API key not found! Set env variable: export " .. provider.api_key_env .. "=<your-key>"
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

  -- Show "sending" indicator
  M.add_message("system", "Sending to " .. provider.name .. " ...")
  -- Remove the "Sending..." system message from display history after response
  local sending_idx = #M.state.history
  table.remove(M.state.history)

  -- Call AI provider asynchronously
  M.call_provider(provider, api_messages, sending_idx)
end

-- Async API call using vim.system (0.10+) or vim.fn.jobstart (fallback)
function M.call_provider(provider, messages, sending_idx)
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

  -- Build curl command arguments
  local cmd_args = { "curl", "-s", "--max-time", "60", "-X", "POST", api_url }
  for _, h in ipairs(headers) do
    table.insert(cmd_args, "-H")
    table.insert(cmd_args, h)
  end
  table.insert(cmd_args, "-d")
  table.insert(cmd_args, request_body)

  local provider_name = provider.name
  local provider_type = provider.type

  -- Parse response helper
  local function parse_response(result_stdout, exit_code)
    local response_text = ""

    if exit_code ~= 0 then
      response_text = "Error: Failed to connect to " .. provider_name .. " (exit code: " .. tostring(exit_code) .. ")"
    else
      local ok, data = pcall(vim.fn.json_decode, result_stdout or "")
      if not ok or not data then
        response_text = "Error: Invalid response from " .. provider_name
      elseif type(data) == "table" and data.error then
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

    return response_text
  end

  -- Try vim.system first (Neovim 0.10+), fallback to jobstart
  if has_vim_system() then
    vim.system(cmd_args, { text = true }, function(result)
      local response_text = parse_response(result.stdout, result.code)
      vim.schedule(function()
        M.add_message("assistant", response_text)
      end)
    end)
  else
    -- Fallback: use vim.fn.jobstart (available since Neovim 0.2+)
    local stdout_chunks = {}
    local job_id = vim.fn.jobstart(cmd_args, {
      stdout_buffered = true,
      on_stdout = function(_, data)
        if data then
          for _, chunk in ipairs(data) do
            if chunk ~= "" then
              table.insert(stdout_chunks, chunk)
            end
          end
        end
      end,
      on_exit = function(_, exit_code)
        local stdout = table.concat(stdout_chunks, "\n")
        local response_text = parse_response(stdout, exit_code)
        vim.schedule(function()
          M.add_message("assistant", response_text)
        end)
      end,
    })

    if job_id <= 0 then
      M.add_message("system", "Error: Failed to start curl. Is curl installed?")
    else
      M.state.pending_job = job_id
    end
  end
end

-- ---------------------------------------------------------------------------
-- Close chat windows
-- ---------------------------------------------------------------------------
function M.close_chat()
  -- Cancel pending job if any
  if M.state.pending_job and M.state.pending_job > 0 then
    pcall(vim.fn.jobstop, M.state.pending_job)
    M.state.pending_job = nil
  end

  -- Close input window first
  if M.state.input_win and vim.api.nvim_win_is_valid(M.state.input_win) then
    pcall(vim.api.nvim_win_close, M.state.input_win, true)
  end
  if M.state.input_buf and vim.api.nvim_buf_is_valid(M.state.input_buf) then
    pcall(vim.api.nvim_buf_delete, M.state.input_buf, { force = true })
  end

  -- Close chat window
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    pcall(vim.api.nvim_win_close, M.state.win, true)
  end
  if M.state.buf and vim.api.nvim_buf_is_valid(M.state.buf) then
    pcall(vim.api.nvim_buf_delete, M.state.buf, { force = true })
  end

  M.state.win = nil
  M.state.buf = nil
  M.state.input_win = nil
  M.state.input_buf = nil
end

-- ---------------------------------------------------------------------------
-- Open chat window
-- ---------------------------------------------------------------------------
function M.open_chat()
  -- If already open, focus the input window
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    if M.state.input_win and vim.api.nvim_win_is_valid(M.state.input_win) then
      pcall(vim.api.nvim_set_current_win, M.state.input_win)
      vim.cmd("startinsert")
    end
    return
  end

  -- Make sure providers are loaded
  if #M.state.providers == 0 then
    M.load_config()
  end

  -- Calculate window dimensions
  local width = math.max(40, math.floor(vim.o.columns * 0.8))
  local total_height = math.max(10, math.floor(vim.o.lines * 0.7))
  local input_height = 3
  local chat_height = math.max(5, total_height - input_height - 2) -- -2 for borders
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - total_height) / 2)

  -- -----------------------------------------------------------------------
  -- Create chat history buffer
  -- -----------------------------------------------------------------------
  M.state.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[M.state.buf].bufhidden = "wipe"
  vim.bo[M.state.buf].buftype = "nofile"
  vim.bo[M.state.buf].modifiable = false
  vim.bo[M.state.buf].filetype = "twen-chat"
  vim.bo[M.state.buf].swapfile = false

  -- Create chat history window
  M.state.win = vim.api.nvim_open_win(M.state.buf, false, {
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
  vim.wo[M.state.win].scrolloff = 2

  -- -----------------------------------------------------------------------
  -- Create input buffer
  -- -----------------------------------------------------------------------
  M.state.input_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[M.state.input_buf].bufhidden = "wipe"
  vim.bo[M.state.input_buf].buftype = "nofile"
  vim.bo[M.state.input_buf].filetype = "twen-chat-input"
  vim.bo[M.state.input_buf].swapfile = false

  -- Create input window (below chat history)
  M.state.input_win = vim.api.nvim_open_win(M.state.input_buf, true, {
    relative = "editor",
    width = width,
    height = input_height,
    col = col,
    row = row + chat_height + 2, -- +2 for the border of the chat window
    style = "minimal",
    border = "rounded",
    title = " Message (Enter=Send | Ctrl+J=NewLine | Esc=Close) ",
    title_pos = "center",
  })
  vim.wo[M.state.input_win].wrap = true
  vim.wo[M.state.input_win].number = false
  vim.wo[M.state.input_win].relativenumber = false
  vim.wo[M.state.input_win].signcolumn = "no"
  vim.wo[M.state.input_win].scrolloff = 0

  -- -----------------------------------------------------------------------
  -- Input buffer keymaps
  -- -----------------------------------------------------------------------
  -- Send message on Enter (in both normal and insert mode)
  local function send_input()
    local lines = vim.api.nvim_buf_get_lines(M.state.input_buf, 0, -1, false)
    local message = table.concat(lines, "\n"):match("^%s*(.-)%s*$")
    if message ~= "" then
      -- Clear input buffer
      vim.bo[M.state.input_buf].modifiable = true
      vim.api.nvim_buf_set_lines(M.state.input_buf, 0, -1, false, {})
      vim.bo[M.state.input_buf].modifiable = false
      M.send_message(message)
    end
    -- Keep focus in input window
    if M.state.input_win and vim.api.nvim_win_is_valid(M.state.input_win) then
      vim.api.nvim_set_current_win(M.state.input_win)
      vim.cmd("startinsert")
    end
  end

  -- Enter sends message
  vim.keymap.set("n", "<CR>", send_input, { buffer = M.state.input_buf, nowait = true, desc = "Send message" })
  vim.keymap.set("i", "<CR>", function()
    -- In insert mode, use <C-o> to execute normal mode command without leaving insert
    -- This avoids the issue where Enter in insert mode doesn't work properly
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
    vim.schedule(send_input)
  end, { buffer = M.state.input_buf, nowait = true, desc = "Send message" })

  -- Ctrl+J inserts a new line (for multiline messages)
  vim.keymap.set("i", "<C-J>", function()
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", false)
  end, { buffer = M.state.input_buf, nowait = true, desc = "Insert newline" })
  vim.keymap.set("n", "<C-J>", function()
    vim.cmd("normal! o")
    vim.cmd("startinsert")
  end, { buffer = M.state.input_buf, nowait = true, desc = "Insert newline" })

  -- Esc closes chat from input window
  vim.keymap.set("n", "<Esc>", function()
    M.close_chat()
  end, { buffer = M.state.input_buf, nowait = true, desc = "Close chat" })
  vim.keymap.set("i", "<Esc>", function()
    M.close_chat()
  end, { buffer = M.state.input_buf, nowait = true, desc = "Close chat" })

  -- Esc on chat history window also closes
  vim.keymap.set("n", "<Esc>", function()
    M.close_chat()
  end, { buffer = M.state.buf, nowait = true, desc = "Close chat" })

  -- q closes chat from history window
  vim.keymap.set("n", "q", function()
    M.close_chat()
  end, { buffer = M.state.buf, nowait = true, desc = "Close chat" })

  -- Prevent accidental buffer wipe causing orphaned windows
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = M.state.buf,
    once = true,
    callback = function()
      M.close_chat()
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = M.state.input_buf,
    once = true,
    callback = function()
      M.close_chat()
    end,
  })

  -- Render initial history
  M.render_history()

  -- Focus input window and enter insert mode
  vim.api.nvim_set_current_win(M.state.input_win)
  vim.cmd("startinsert")
end

-- ---------------------------------------------------------------------------
-- Open provider settings UI
-- ---------------------------------------------------------------------------
function M.open_settings()
  -- Load providers if not loaded
  if #M.state.providers == 0 then
    M.load_config()
  end

  local width = math.min(70, vim.o.columns - 4)
  local num_providers = #M.state.providers
  local height = math.min(num_providers * 5 + 6, vim.o.lines - 4)
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  M.state.settings_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[M.state.settings_buf].bufhidden = "wipe"
  vim.bo[M.state.settings_buf].buftype = "nofile"
  vim.bo[M.state.settings_buf].filetype = "twen-chat-settings"
  vim.bo[M.state.settings_buf].modifiable = false
  vim.bo[M.state.settings_buf].swapfile = false

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
  vim.wo[M.state.settings_win].scrolloff = 0

  -- Render settings content
  M.render_settings()

  -- Move cursor to first provider item (line 4)
  pcall(vim.api.nvim_win_set_cursor, M.state.settings_win, { 4, 0 })

  -- -----------------------------------------------------------------------
  -- Settings keymaps
  -- -----------------------------------------------------------------------
  -- Select provider (x or Enter)
  local function select_provider()
    local cursor = vim.api.nvim_win_get_cursor(M.state.settings_win)
    local line_num = cursor[1]
    for i, p in ipairs(M.state.providers) do
      local target_line = 3 + (i - 1) * 5 + 1
      if line_num >= target_line and line_num <= target_line + 3 then
        M.state.provider = p.id
        vim.notify("Provider set to: " .. p.name, vim.log.levels.INFO)
        M.render_settings()
        -- Restore cursor position
        pcall(vim.api.nvim_win_set_cursor, M.state.settings_win, { target_line, 0 })
        break
      end
    end
  end

  -- Navigate down (j or Down arrow)
  local function move_down()
    local cursor = vim.api.nvim_win_get_cursor(M.state.settings_win)
    local line_num = cursor[1]
    -- Find next provider block start
    for i, _ in ipairs(M.state.providers) do
      local target_line = 3 + (i - 1) * 5 + 1
      if target_line > line_num then
        pcall(vim.api.nvim_win_set_cursor, M.state.settings_win, { target_line, 0 })
        break
      end
    end
  end

  -- Navigate up (k or Up arrow)
  local function move_up()
    local cursor = vim.api.nvim_win_get_cursor(M.state.settings_win)
    local line_num = cursor[1]
    -- Find previous provider block start
    local prev_line = 4 -- first provider
    for i, _ in ipairs(M.state.providers) do
      local target_line = 3 + (i - 1) * 5 + 1
      if target_line >= line_num then
        break
      end
      prev_line = target_line
    end
    pcall(vim.api.nvim_win_set_cursor, M.state.settings_win, { prev_line, 0 })
  end

  vim.keymap.set("n", "<CR>", select_provider, { buffer = M.state.settings_buf, nowait = true, desc = "Select provider" })
  vim.keymap.set("n", "x", select_provider, { buffer = M.state.settings_buf, nowait = true, desc = "Select provider" })
  vim.keymap.set("n", "j", move_down, { buffer = M.state.settings_buf, nowait = true, desc = "Next provider" })
  vim.keymap.set("n", "<Down>", move_down, { buffer = M.state.settings_buf, nowait = true, desc = "Next provider" })
  vim.keymap.set("n", "k", move_up, { buffer = M.state.settings_buf, nowait = true, desc = "Previous provider" })
  vim.keymap.set("n", "<Up>", move_up, { buffer = M.state.settings_buf, nowait = true, desc = "Previous provider" })

  -- Save and close (Ctrl+S)
  vim.keymap.set("n", "<C-s>", function()
    M.save_config()
    vim.notify("Twen Chat settings saved!", vim.log.levels.INFO)
    if M.state.settings_win and vim.api.nvim_win_is_valid(M.state.settings_win) then
      vim.api.nvim_win_close(M.state.settings_win, true)
    end
  end, { buffer = M.state.settings_buf, nowait = true, desc = "Save settings" })

  -- Close without saving (Esc or q)
  vim.keymap.set("n", "<Esc>", function()
    if M.state.settings_win and vim.api.nvim_win_is_valid(M.state.settings_win) then
      vim.api.nvim_win_close(M.state.settings_win, true)
    end
  end, { buffer = M.state.settings_buf, nowait = true, desc = "Close settings" })
  vim.keymap.set("n", "q", function()
    if M.state.settings_win and vim.api.nvim_win_is_valid(M.state.settings_win) then
      vim.api.nvim_win_close(M.state.settings_win, true)
    end
  end, { buffer = M.state.settings_buf, nowait = true, desc = "Close settings" })
end

-- ---------------------------------------------------------------------------
-- Render settings content
-- ---------------------------------------------------------------------------
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
  table.insert(lines, "  j/k: Navigate | Enter/x: Select | Ctrl+s: Save | Esc/q: Exit")

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
end

-- ---------------------------------------------------------------------------
-- Setup function - called on Neovim startup
-- ---------------------------------------------------------------------------
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
