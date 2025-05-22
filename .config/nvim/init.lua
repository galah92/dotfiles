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
vim.opt.scrolloff = 5  -- Minimal number of screen lines to keep above and below the cursor

vim.opt.splitright = true -- Open new splits to the right
vim.opt.splitbelow = true -- Open new splits below

vim.opt.breakindent = true -- Enable break indent
vim.opt.undofile = true -- Save undo history

vim.opt.ignorecase = true -- Ignore case in search patterns
vim.opt.smartcase = true -- Override 'ignorecase' if search pattern contains upper case characters

-- vim.opt.cmdheight = 0
vim.opt.laststatus = 0

vim.opt.list = true -- Show invisible characters
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' } -- Set characters to display for tabs, trailing spaces, and non-breaking spaces

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>') -- Clear highlights on search when pressing <Esc> in normal mode

vim.keymap.set("n", "yc", "yygccp", {remap=true}) -- Duplicate a line and comment out the first line

-- Move selected lines
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

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
    'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically

    { -- Adds git related signs to the gutter, as well as utilities for managing changes
      'lewis6991/gitsigns.nvim',
      opts = {},
    },

    { -- Highlight and search for todo comments like TODO, HACK, BUG
      "folke/todo-comments.nvim",
      dependencies = { "nvim-lua/plenary.nvim" },
    },

    {
      "ibhagwan/fzf-lua",
      -- optional for icon support
      dependencies = { "nvim-tree/nvim-web-devicons" },
      -- or if using mini.icons/mini.nvim
      -- dependencies = { "echasnovski/mini.icons" },
      opts = {
        -- winopts = { row = 1, col = 0 },
        defaults = { file_icons = false },
      },
    },

    {
      'shaunsingh/nord.nvim',
      lazy = false, -- make sure we load this during startup if it is your main colorscheme
      priority = 1000, -- make sure to load this before all the other start plugins
      init = function()
        vim.g.nord_contrast = true
        vim.g.nord_borders = true
        vim.g.nord_italic = false
        vim.g.nord_bold = false
      end
    },

    'slugbyte/lackluster.nvim',
    'wnkz/monoglow.nvim',
    'aliqyan-21/darkvoid.nvim',
    'datsfilipe/vesper.nvim',
    {
      "rose-pine/neovim",
      name = "rose-pine",
      opts = {
        styles = {
          italic = false,
        },
      },
    },
    {
      'sainnhe/everforest',
      lazy = false,
      priority = 1000,
      init = function()
        -- vim.g.everforest_background = 'medium'
        -- vim.g.everforest_transparent_background = 1
        vim.g.everforest_better_performance = 1
      end
    },
    {
      'AlexvZyl/nordic.nvim',
      lazy = false,
      priority = 1000,
    },

    'github/copilot.vim',
    
  {
     'm4xshen/hardtime.nvim',
     lazy = false,
     dependencies = { 'MunifTanjim/nui.nvim' },
     opts = {},
  },

  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs', -- Sets main module to use for opts
    -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
    opts = {
      ensure_installed = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' },
      -- Autoinstall languages that are not installed
      auto_install = true,
      highlight = {
        enable = true,
        -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
        --  If you are experiencing weird indenting issues, add the language to
        --  the list of additional_vim_regex_highlighting and disabled languages for indent.
        additional_vim_regex_highlighting = { 'ruby' },
      },
      indent = { enable = true, disable = { 'ruby' } },
    },
    -- There are additional nvim-treesitter modules that you can use to interact
    -- with nvim-treesitter. You should go explore a few and see what interests you:
    --
    --    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
    --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
    --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
  },

  },
  -- Configure any other settings here. See the documentation for more details.
  -- colorscheme that will be used when installing plugins.
  install = { colorscheme = { "habamax" } },
  -- automatically check for plugin updates
  checker = { enabled = true, notify = false },
})

vim.cmd("colorscheme nord")

vim.lsp.config['ruff'] = {
  cmd = { 'uv', 'run', 'ruff', 'server' },
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', 'ruff.toml', '.ruff.toml', '.git' },
  settings = {},
}

vim.lsp.config['ty'] = {
  cmd = { 'uv', 'run', 'ty', 'server' },
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', 'ty.toml', '.git' },
  settings = {},
}

vim.lsp.config['rust-analyzer'] = {
  cmd = { 'rust-analyzer' },
  filetypes = { 'rust' },
  root_markers = { 'Cargo.toml', 'Cargo.lock', '.git' },
  settings = {},
  init_options = { ["checkOnSave"] = { command = "clippy" } },
}

vim.lsp.enable({
  "ruff",
  "ty",
  "rust-analyzer",
})

vim.diagnostic.config({
  virtual_text = true, -- Show diagnostics inline
})

vim.api.nvim_set_keymap('n', '<leader>f', ':lua vim.lsp.buf.format()<CR>', { noremap = true, silent = true, desc = 'Format file' })

vim.keymap.set("n", "<C-\\>", [[<Cmd>lua require"fzf-lua".buffers()<CR>]], {})
vim.keymap.set("n", "<C-k>", [[<Cmd>lua require"fzf-lua".builtin()<CR>]], {})
vim.keymap.set("n", "<C-p>", [[<Cmd>lua require"fzf-lua".files()<CR>]], {})
vim.keymap.set("n", "<C-l>", [[<Cmd>lua require"fzf-lua".live_grep_glob()<CR>]], {})
vim.keymap.set("n", "<C-g>", [[<Cmd>lua require"fzf-lua".grep_project()<CR>]], {})
vim.keymap.set("n", "<F1>", [[<Cmd>lua require"fzf-lua".help_tags()<CR>]], {})

