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

vim.pack.add({
  'https://github.com/tpope/vim-sleuth',                  -- Detect tabstop, expandtab and shiftwidth automatically
  'https://github.com/lewis6991/gitsigns.nvim',           -- Color line numbers with git changes
  'https://github.com/ibhagwan/fzf-lua',                  -- Fuzzy finder
  'https://github.com/nvim-treesitter/nvim-treesitter',   -- Treesitter
  'https://github.com/mks-h/treesitter-autoinstall.nvim', -- Auto install treesitter parsers and enable highlight
  'https://github.com/github/copilot.vim',                -- GitHub Copilot

  -- Colorschemes
  'https://github.com/m6vrm/gruber.vim',
  'https://github.com/savq/melange-nvim',
  'https://github.com/xero/miasma.nvim',
  'https://github.com/ptdewey/darkearth-nvim',
})

require('fzf-lua').setup({ 'border-fused', winopts = { fullscreen = true } })
require('treesitter-autoinstall').setup({ highlight = true })

vim.g.melange_enable_font_variants = { italic = false, bold = true, underline = true, undercurl = true, strikethrough = true }

vim.lsp.config['ruff'] = {
  cmd = { 'uv', 'run', 'ruff', 'server' },
  filetypes = { 'python' },
}

vim.lsp.config['ty'] = {
  cmd = { 'uv', 'run', 'ty', 'server' },
  filetypes = { 'python' },
}

vim.lsp.config['rust-analyzer'] = {
  cmd = { 'rust-analyzer' },
  filetypes = { 'rust' },
  init_options = { ['check'] = { command = 'clippy' } },
}

vim.lsp.config['clangd'] = {
  cmd = { 'clangd' },
  filetypes = { 'c', 'cpp', 'cuda' },
}

vim.lsp.config['lua'] = {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  settings = { Lua = { diagnostics = { globals = { 'vim' } } } }, -- https://stackoverflow.com/a/79656109
}

vim.lsp.config['tombi'] = {
  cmd = { 'uvx', 'tombi', 'lsp' },
  filetypes = { 'toml' },
}

vim.lsp.enable({
  'ruff',
  'ty',
  'rust-analyzer',
  'clangd',
  'lua',
  'tombi',
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
