vim.g.mapleader = ' ' -- Set leader key (must happen before plugins are loaded)
vim.g.maplocalleader = ' ' -- Set local leader key
vim.opt.mouse = 'a' -- Enable mouse support
vim.opt.clipboard = 'unnamedplus' -- Sync clipboard between OS and Neovim
vim.opt.relativenumber = true -- Show relative line numbers
vim.opt.number = true -- Show current aboslute line number
vim.opt.cursorline = true -- Highlight current line
vim.opt.signcolumn = 'yes' -- Always show signcolumn
vim.opt.guicursor = "" -- Set block cursor in insert mode
vim.opt.splitright = true -- Open new splits to the right
vim.opt.splitbelow = true -- Open new splits below
vim.opt.breakindent = true -- Enable break indent
vim.opt.undofile = true -- Save undo history
vim.opt.ignorecase = true -- Ignore case in search patterns
vim.opt.smartcase = true -- Override 'ignorecase' if search pattern contains upper case characters
vim.opt.laststatus = 0 -- Hide the statusline
vim.opt.list = true -- Show invisible characters
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' } -- Set characters to display for invisible characters

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
    { 'ibhagwan/fzf-lua', opts = { winopts = { fullscreen = true, border = 'none', }, }, },
    'github/copilot.vim',
    'bjarneo/pixel.nvim',
    {
      'nvim-treesitter/nvim-treesitter',
      main = 'nvim-treesitter.configs',
      build = ":TSUpdate",
      opts = {
        ensure_installed = { 'c', 'cpp', 'python', 'rust', 'lua', 'bash', 'json', 'yaml', 'toml' },
        auto_install = true,
        highlight = { enable = true },
      },
    },
  },
})

vim.lsp.config['ruff'] = {
  cmd = { 'uv', 'run', 'ruff', 'server' },
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', 'ruff.toml' },
}

vim.lsp.config['ty'] = {
  cmd = { 'uv', 'run', 'ty', 'server' },
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', 'ty.toml' },
}

vim.lsp.config['rust-analyzer'] = {
  cmd = { 'rust-analyzer' },
  filetypes = { 'rust' },
  root_markers = { 'Cargo.toml', 'Cargo.lock' },
  init_options = { ["check"] = { command = "clippy" } },
}

vim.lsp.config['clangd'] = {
  cmd = { 'clangd' },
  filetypes = { 'c', 'cpp', 'cuda' },
  root_markers = { 'compile_commands.json', '.clangd' },
}

vim.lsp.config['lua'] = {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = { '.luarc.json' },
  settings = { Lua = { diagnostics = { globals = { 'vim' }, }, }, }, -- Add 'vim' to the list of global variables
}

vim.lsp.config['tombi'] = {
  cmd = { 'uvx', 'tombi', 'lsp' },
  filetypes = { 'toml' },
  root_markers = { 'tombi.toml', 'pyproject.toml' },
}

vim.lsp.config['rumdl'] = {
  cmd = { 'uvx', 'rumdl', 'server' },
  filetypes = { 'markdown' },
  root_markers = { '.git' },
}

vim.lsp.enable({
  "ruff",
  "ty",
  "rust-analyzer",
  "clangd",
  "lua",
  "tombi",
  -- "rumdl",
})

vim.diagnostic.config({
  virtual_text = true, -- Show diagnostics inline
})

vim.keymap.set('n', '<leader>f', vim.lsp.buf.format, { desc = 'vim.lsp.buf.format()' })                         -- Format current buffer
vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { desc = 'vim.lsp.buf.code_action()' })              -- Show code actions
vim.keymap.set("n", "<leader>i", function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled()) end) -- Toggle inlay hints
vim.keymap.set("n", "<C-p>", [[<Cmd>lua require"fzf-lua".global()<CR>]], {})                                    -- Fuzzy file finder
vim.keymap.set("n", "<C-l>", [[<Cmd>lua require"fzf-lua".live_grep()<CR>]], {})                                 -- Fuzzy live grep
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')                                                             -- Clear highlights on search when pressing <Esc> in normal mode
vim.keymap.set("n", "yc", "yygccp", { remap = true })                                                           -- Duplicate a line and comment out the first line
