--- minimal.lua - ANSI colorscheme for use with terminal palettes
--- Inspired by minimum.lua (bold keywords) and koda.nvim (green strings, yellow numbers)
--- Uses termguicolors=false so Ghostty/terminal controls the actual colors

vim.opt.termguicolors = false

vim.cmd("hi clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end
vim.g.colors_name = "minimal"

-- ANSI color reference (actual colors come from terminal palette):
-- 0=black, 1=red, 2=green, 3=yellow, 4=blue, 5=magenta, 6=cyan, 7=cursorline
-- 8=grey (comments), 9=diff del bg, 10=diff add bg, 11=diff change bg, 12=visual bg

local function hi(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- =============================================================================
-- Editor UI
-- =============================================================================
hi("Normal", { ctermfg = "NONE", ctermbg = "NONE" })
hi("FloatBorder", { ctermfg = 8 })
hi("FloatTitle", { cterm = { bold = true } })

hi("LineNr", { ctermfg = 8 })
hi("CursorLineNr", { ctermfg = "NONE", cterm = { bold = true } })
hi("CursorLine", { ctermbg = 12 })
hi("ColorColumn", { ctermbg = 8 })
hi("SignColumn", { ctermfg = 8 })

hi("Visual", { ctermbg = 12 })
hi("Search", { ctermbg = 11, ctermfg = 3 })
hi("IncSearch", { ctermbg = 3, ctermfg = 0 })
hi("CurSearch", { ctermbg = 3, ctermfg = 0, cterm = { bold = true } })

hi("Pmenu", { ctermfg = "NONE", ctermbg = "NONE" })
hi("PmenuSel", { cterm = { bold = true, reverse = true } })
hi("PmenuSbar", { ctermbg = 8 })
hi("PmenuThumb", { ctermbg = 7 })

hi("StatusLine", { ctermfg = "NONE", ctermbg = "NONE", cterm = { bold = true } })
hi("StatusLineNC", { ctermfg = 8, ctermbg = "NONE" })
hi("WinSeparator", { ctermfg = 8 })

hi("Folded", { ctermfg = 8 })
hi("FoldColumn", { ctermfg = 8 })
hi("NonText", { ctermfg = 8 })
hi("EndOfBuffer", { ctermfg = 8 })
hi("SpecialKey", { ctermfg = 8 })
hi("Whitespace", { ctermfg = 8 })

hi("Directory", { cterm = { bold = true } })
hi("Title", { cterm = { bold = true } })
hi("MoreMsg", { ctermfg = 2 })
hi("Question", { ctermfg = 2 })
hi("ErrorMsg", { ctermfg = 1, cterm = { bold = true } })
hi("WarningMsg", { ctermfg = 3 })
hi("ModeMsg", { cterm = { bold = true } })

hi("MatchParen", { cterm = { bold = true } })
hi("Cursor", { cterm = { reverse = true } })

-- =============================================================================
-- Diff
-- =============================================================================
hi("DiffAdd", { ctermbg = 10, ctermfg = 2 })
hi("DiffChange", { ctermbg = 11, ctermfg = 3 })
hi("DiffDelete", { ctermbg = 9, ctermfg = 1 })
hi("DiffText", { ctermbg = 11, ctermfg = 3, cterm = { bold = true } })
hi("Added", { ctermfg = 2 })
hi("Changed", { ctermfg = 3 })
hi("Removed", { ctermfg = 1 })

-- =============================================================================
-- Syntax (the core philosophy: bold for structure, color for literals)
-- =============================================================================

-- Default: plain
hi("Identifier", { ctermfg = "NONE" })
hi("Function", { ctermfg = "NONE" })
hi("Delimiter", { ctermfg = "NONE" })
hi("Operator", { ctermfg = "NONE" })
hi("Special", { ctermfg = "NONE" })

-- Comments: grey
hi("Comment", { ctermfg = 8 })

-- Strings: green
hi("String", { ctermfg = 2 })
hi("Character", { ctermfg = 2 })

-- Numbers/Constants: yellow
hi("Number", { ctermfg = 3 })
hi("Float", { ctermfg = 3 })
hi("Boolean", { ctermfg = 3 })
hi("Constant", { ctermfg = 3 })

-- Keywords: bold
hi("Statement", { cterm = { bold = true } })
hi("Conditional", { cterm = { bold = true } })
hi("Repeat", { cterm = { bold = true } })
hi("Label", { cterm = { bold = true } })
hi("Keyword", { cterm = { bold = true } })
hi("Exception", { cterm = { bold = true } })

-- Types: plain (TODO: revisit - maybe bold for type annotations?)
hi("Type", { ctermfg = "NONE" })
hi("StorageClass", { cterm = { bold = true } })
hi("Structure", { cterm = { bold = true } })
hi("Typedef", { cterm = { bold = true } })

-- Preprocessor: bold
hi("PreProc", { cterm = { bold = true } })
hi("Include", { cterm = { bold = true } })
hi("Define", { cterm = { bold = true } })
hi("Macro", { cterm = { bold = true } })

-- Tags and special
hi("Tag", { ctermfg = "NONE" })
hi("SpecialChar", { ctermfg = 2 })
hi("SpecialComment", { ctermfg = 8, cterm = { bold = true } })

-- Errors/Todos
hi("Error", { ctermfg = 1, cterm = { bold = true } })
hi("Todo", { ctermfg = 3, cterm = { bold = true } })
hi("Underlined", { cterm = { underline = true } })

-- =============================================================================
-- Treesitter (only overrides, rest falls back to standard groups)
-- =============================================================================
hi("@module", { ctermfg = "NONE" })
hi("@type.definition", { ctermfg = "NONE" })
hi("@string.documentation", { link = "Comment" })
hi("@comment.error", { ctermfg = 1, cterm = { bold = true } })
hi("@comment.warning", { ctermfg = 3, cterm = { bold = true } })
hi("@comment.todo", { ctermfg = 3, cterm = { bold = true } })
hi("@comment.note", { ctermfg = 4, cterm = { bold = true } })

-- Markup
hi("@markup.strong", { cterm = { bold = true } })
hi("@markup.italic", { cterm = { italic = true } })
hi("@markup.strikethrough", { cterm = { strikethrough = true } })
hi("@markup.underline", { cterm = { underline = true } })
hi("@markup.heading", { cterm = { bold = true } })
hi("@markup.quote", { link = "Comment" })
hi("@markup.link", { cterm = { underline = true } })
hi("@markup.raw", { ctermfg = 8 })

-- Tags (HTML/XML)
hi("@tag", { cterm = { bold = true } })
hi("@tag.attribute", { ctermfg = "NONE" })
hi("@tag.delimiter", { ctermfg = 8 })

-- Language-specific overrides
hi("@string.yaml", { ctermfg = "NONE" })  -- YAML values are strings but look better plain

-- =============================================================================
-- Diagnostics
-- =============================================================================
hi("DiagnosticError", { ctermfg = 1 })
hi("DiagnosticWarn", { ctermfg = 3 })
hi("DiagnosticInfo", { ctermfg = 4 })
hi("DiagnosticHint", { ctermfg = 8 })
hi("DiagnosticOk", { ctermfg = 2 })

hi("DiagnosticUnderlineError", { cterm = { undercurl = true }, ctermfg = 1 })
hi("DiagnosticUnderlineWarn", { cterm = { undercurl = true }, ctermfg = 3 })
hi("DiagnosticUnderlineInfo", { cterm = { undercurl = true }, ctermfg = 4 })
hi("DiagnosticUnderlineHint", { cterm = { undercurl = true }, ctermfg = 8 })
hi("DiagnosticUnderlineOk", { cterm = { undercurl = true }, ctermfg = 2 })

hi("DiagnosticDeprecated", { cterm = { strikethrough = true } })
hi("DiagnosticUnnecessary", { ctermfg = 8 })

-- =============================================================================
-- Plugins
-- =============================================================================
hi("GitSignsAdd", { ctermfg = 2 })
hi("GitSignsChange", { ctermfg = 3 })
hi("GitSignsDelete", { ctermfg = 1 })

hi("IblIndent", { ctermfg = 8 })
hi("IblScope", { ctermfg = "NONE" })
