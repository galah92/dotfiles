-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.opt.mouse = 'a' -- Enable mouse support
vim.opt.relativenumber = true -- Show relative line numbers
vim.opt.number = true -- Show current aboslute line number
vim.opt.showmode = false -- Don't show mode, it's already in the status line
vim.opt.cursorline = true -- Highlight current line
vim.opt.signcolumn = 'yes' -- Always show signcolumn
vim.opt.guicursor = "" -- Set block cursor in insert mode
vim.opt.scrolloff = 10  -- Minimal number of screen lines to keep above and below the cursor

vim.opt.splitright = true -- Open new splits to the right
vim.opt.splitbelow = true -- Open new splits below

vim.opt.breakindent = true -- Enable break indent
vim.opt.undofile = true -- Save undo history

vim.opt.ignorecase = true -- Ignore case in search patterns
vim.opt.smartcase = true -- Override 'ignorecase' if search pattern contains upper case characters

vim.opt.cmdheight = 0
vim.opt.laststatus = 3

vim.opt.list = true -- Show invisible characters
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' } -- Set characters to display for tabs, trailing spaces, and non-breaking spaces

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>') -- Clear highlights on search when pressing <Esc> in normal mode

vim.schedule(function() -- Schedule the setting after `UiEnter` because it can increase startup-time
  vim.opt.clipboard = 'unnamedplus' -- Sync clipboard between OS and Neovim
end)

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

    { -- Highlight and search for todo comments like TODO, HACK, BUG
      "folke/todo-comments.nvim",
      dependencies = { "nvim-lua/plenary.nvim" },
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
            },
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
