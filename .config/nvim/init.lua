-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.opt.mouse = 'a'               -- Enable mouse support
vim.opt.clipboard = 'unnamedplus' -- Sync clipboard between OS and Neovim
vim.g.clipboard = {               -- Support copying and pasting over SSH using OSC 52
  name = 'OSC 52',
  copy = {
    ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
    ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
  },
  paste = {
    ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
    ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
  },
}

vim.opt.relativenumber = true -- Show relative line numbers
vim.opt.number = true         -- Show current aboslute line number
vim.opt.cursorline = true     -- Highlight current line
vim.opt.signcolumn = 'yes'    -- Always show signcolumn
vim.opt.guicursor = ""        -- Set block cursor in insert mode

vim.opt.splitright = true     -- Open new splits to the right
vim.opt.splitbelow = true     -- Open new splits below

vim.opt.breakindent = true    -- Enable break indent
vim.opt.undofile = true       -- Save undo history

vim.opt.ignorecase = true     -- Ignore case in search patterns
vim.opt.smartcase = true      -- Override 'ignorecase' if search pattern contains upper case characters

vim.opt.laststatus = 0

vim.opt.list = true -- Show invisible characters
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' } -- Set characters to display for tabs, trailing spaces, and non-breaking spaces

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>') -- Clear highlights on search when pressing <Esc> in normal mode

vim.keymap.set("n", "yc", "yygccp", { remap = true }) -- Duplicate a line and comment out the first line

-- Move selected lines
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out,                            "WarningMsg" },
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
    'tpope/vim-sleuth',        -- Detect tabstop, expandtab and shiftwidth automatically
    'lewis6991/gitsigns.nvim', -- Adds git related signs to the gutter
    { 'ibhagwan/fzf-lua', opts = { defaults = { file_icons = false }, }, },
    'github/copilot.vim',
    {
      'nvim-treesitter/nvim-treesitter',
      main = 'nvim-treesitter.configs',
      build = ":TSUpdate",
      opts = {
        ensure_installed = { 'c', 'cpp', 'python', 'rust', 'lua', 'bash', 'json', 'yaml', 'toml' },
        highlight = { enable = true },
      },
    },
  },
})

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
  init_options = { ["check"] = { command = "clippy" } },
}

vim.lsp.config['clangd'] = {
  cmd = { 'clangd' },
  filetypes = { 'c', 'cpp' },
  root_markers = { 'compile_commands.json', '.clangd' },
  settings = {},
}

vim.lsp.config['lua'] = {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = { '.luarc.json' },
  settings = { Lua = { diagnostics = { globals = { 'vim' }, }, }, }, -- Add 'vim' to the list of global variables
}

vim.lsp.enable({
  "ruff",
  "ty",
  "rust-analyzer",
  "clangd",
  "lua",
})

vim.diagnostic.config({
  virtual_text = true, -- Show diagnostics inline
})

vim.api.nvim_set_keymap('n', '<leader>f', ':lua vim.lsp.buf.format()<CR>',
  { noremap = true, silent = true, desc = 'Format file' })

vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { desc = 'Code Action' })

vim.keymap.set("n", "<C-\\>", [[<Cmd>lua require"fzf-lua".buffers()<CR>]], {})
vim.keymap.set("n", "<C-k>", [[<Cmd>lua require"fzf-lua".builtin()<CR>]], {})
vim.keymap.set("n", "<C-p>", [[<Cmd>lua require"fzf-lua".files()<CR>]], {})
vim.keymap.set("n", "<C-l>", [[<Cmd>lua require"fzf-lua".live_grep_glob()<CR>]], {})
vim.keymap.set("n", "<C-g>", [[<Cmd>lua require"fzf-lua".grep_project()<CR>]], {})
vim.keymap.set("n", "<F1>", [[<Cmd>lua require"fzf-lua".help_tags()<CR>]], {})
