-- Twen Vim Dashboard - Custom startup screen with "Welcome to Twen Vim"
return {
  {
    "goolord/alpha-nvim",
    event = "VimEnter",
    opts = function()
      local dashboard = require("alpha.themes.dashboard")

      -- Twen Vim ASCII Banner
      dashboard.section.header.val = {
        "                                                          ",
        "                                                          ",
        "  ████████╗███████╗███╗   ██╗███████╗                    ",
        "  ╚══██╔══╝██╔════╝████╗  ██║██╔════╝                    ",
        "     ██║   █████╗  ██╔██╗ ██║███████╗                    ",
        "     ██║   ██╔══╝  ██║╚██╗██║╚════██║                    ",
        "     ██║   ███████╗██║ ╚████║███████║                    ",
        "     ╚═╝   ╚══════╝╚═╝  ╚═══╝╚══════╝                    ",
        "                                                          ",
        "  ███╗   ██╗███████╗██╗███╗   ███╗                       ",
        "  ████╗  ██║██╔════╝██║████╗ ████║                       ",
        "  ██╔██╗ ██║█████╗  ██║██╔████╔██║                       ",
        "  ██║╚██╗██║██╔══╝  ██║██║╚██╔╝██║                       ",
        "  ██║ ╚████║███████╗██║██║ ╚═╝ ██║                       ",
        "  ╚═╝  ╚═══╝╚══════╝╚═╝╚═╝     ╚═╝                       ",
        "                                                          ",
        "          Welcome to Twen Vim                             ",
        "          LazyVim-based Neovim Framework                  ",
        "                                                          ",
      }

      dashboard.section.header.opts.hl = "Keyword"

      -- Menu buttons
      dashboard.section.buttons.val = {
        dashboard.button("f", " " .. " Find File", ":Telescope find_files <CR>"),
        dashboard.button("r", " " .. " Recent Files", ":Telescope oldfiles <CR>"),
        dashboard.button("g", " " .. " Find Text", ":Telescope live_grep <CR>"),
        dashboard.button("c", " " .. " Twen Chat", ":Chat <CR>"),
        dashboard.button("s", " " .. " Chat Settings", ":ChatSet <CR>"),
        dashboard.button("l", " " .. " Lazy Plugins", ":Lazy <CR>"),
        dashboard.button("q", " " .. " Quit", ":qa <CR>"),
      }

      -- Footer
      dashboard.section.footer.val = {
        "  Twen Vim  -  Your AI-powered Neovim IDE",
      }
      dashboard.section.footer.opts.hl = "Comment"

      -- Send config to alpha
      return dashboard
    end,
    config = function(_, dashboard)
      -- Close Lazy and re-open alpha on startup
      if vim.o.filetype == "lazy" then
        vim.cmd.close()
        vim.api.nvim_create_autocmd("User", {
          pattern = "AlphaReady",
          callback = function()
            require("lazy").show()
          end,
        })
      end
      require("alpha").setup(dashboard.config)
    end,
  },
}
