-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Make line numbers default
vim.opt.number = true
vim.opt.relativenumber = true

-- Enable mouse mode, can be useful for resizing splits for example!
vim.opt.mouse = 'a'

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

-- Enable break indent
vim.opt.breakindent = true

-- Save undo history
vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Keep signcolumn on by default
vim.opt.signcolumn = 'yes'

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Preview substitutions live, as you type!
vim.opt.inccommand = 'split'

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Set block cursor in insert mode
vim.opt.guicursor = ""

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

vim.opt.cmdheight = 0
vim.opt.laststatus = 3

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    -- add your plugins here

    'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically

    { -- Adds git related signs to the gutter, as well as utilities for managing changes
      'lewis6991/gitsigns.nvim',
      opts = {
--         signs = {
--           add = { text = '+' },
--           change = { text = '~' },
--           delete = { text = '_' },
--           topdelete = { text = '‾' },
--           changedelete = { text = '~' },
--         },
      },
    },

    {
      'shaunsingh/nord.nvim',
      lazy = false,
      priority = 1000,
      init = function()
        vim.g.nord_contrast = true
        vim.g.nord_borders = true
        vim.g.nord_italic = false
        vim.cmd.colorscheme "nord"
      end
    },

--     {
--       "slugbyte/lackluster.nvim",
--       lazy = false,
--       priority = 1000,
--       init = function()
--           vim.cmd.colorscheme("lackluster")
--           -- vim.cmd.colorscheme("lackluster-hack") -- my favorite
--           -- vim.cmd.colorscheme("lackluster-mint")
--       end,
--     },

--     {
--       "wnkz/monoglow.nvim",
--       lazy = false,
--       priority = 1000,
--       opts = {},
--       init = function()
--         vim.cmd.colorscheme("monoglow")
--       end
--     },

    'github/copilot.vim',

    'ofseed/copilot-status.nvim',
    {
      'nvim-lualine/lualine.nvim',
      dependencies = { 'nvim-tree/nvim-web-devicons' },
      opts = {
        options = {
          icons_enabled = false,
          component_separators = '|',
          section_separators = '',
        },
        sections = {
          lualine_x = {
            {
              'copilot',
              show_running = True,
              symbols = {
                status = {
                  enabled = 'Copilot',
                  disabled = '',
                },
              },
            }
          },
        },
      },
    },

  },
  -- Configure any other settings here. See the documentation for more details.
  -- colorscheme that will be used when installing plugins.
  install = { colorscheme = { "habamax" } },
  -- automatically check for plugin updates
  checker = { enabled = true },
})
