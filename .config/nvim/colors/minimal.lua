--- ANSI colorscheme for use with terminal palettes
--- Inspired by minimum.lua (bold keywords) and koda.nvim:
--- https://github.com/telemachus/dotfiles/blob/main/config/nvim/colors/minimum.lua
--- https://github.com/oskarnurm/koda.nvim

vim.opt.termguicolors = false

vim.cmd("hi clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end
vim.g.colors_name = "minimal"

local function hi(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- Editor UI
hi("Normal", { ctermfg = "NONE", ctermbg = "NONE" })
hi("FloatBorder", { ctermfg = "DarkGray" })
hi("FloatTitle", { cterm = { bold = true } })

hi("LineNr", { ctermfg = "DarkGray" })
hi("CursorLineNr", { ctermfg = "NONE", cterm = { bold = true } })
hi("CursorLine", { ctermbg = "Blue" })
hi("ColorColumn", { ctermbg = "Blue" })
hi("SignColumn", { ctermfg = "DarkGray" })

hi("Visual", { ctermbg = "Blue" })
hi("Search", { ctermbg = "Yellow", ctermfg = "DarkYellow" })
hi("IncSearch", { ctermbg = "DarkYellow", ctermfg = "Black" })
hi("CurSearch", { ctermbg = "DarkYellow", ctermfg = "Black", cterm = { bold = true } })

hi("Pmenu", { ctermfg = "NONE", ctermbg = "NONE" })
hi("PmenuSel", { cterm = { bold = true, reverse = true } })
hi("PmenuSbar", { ctermbg = "DarkGray" })
hi("PmenuThumb", { ctermbg = "Gray" })

hi("StatusLine", { ctermfg = "NONE", ctermbg = "NONE", cterm = { bold = true } })
hi("StatusLineNC", { ctermfg = "DarkGray", ctermbg = "NONE" })
hi("WinSeparator", { ctermfg = "DarkGray" })

hi("Folded", { ctermfg = "DarkGray" })
hi("FoldColumn", { ctermfg = "DarkGray" })
hi("NonText", { ctermfg = "DarkGray" })
hi("EndOfBuffer", { ctermfg = "DarkGray" })
hi("SpecialKey", { ctermfg = "DarkGray" })
hi("Whitespace", { ctermfg = "DarkGray" })

hi("Directory", { cterm = { bold = true } })
hi("Title", { cterm = { bold = true } })
hi("MoreMsg", { ctermfg = "DarkGreen" })
hi("Question", { ctermfg = "DarkGreen" })
hi("ErrorMsg", { ctermfg = "DarkRed", cterm = { bold = true } })
hi("WarningMsg", { ctermfg = "DarkYellow" })
hi("ModeMsg", { cterm = { bold = true } })

hi("MatchParen", { cterm = { bold = true } })
hi("Cursor", { cterm = { reverse = true } })

-- Diff
hi("DiffAdd", { ctermbg = "Green", ctermfg = "DarkGreen" })
hi("DiffChange", { ctermbg = "Yellow", ctermfg = "DarkYellow" })
hi("DiffDelete", { ctermbg = "Red", ctermfg = "DarkRed" })
hi("DiffText", { ctermbg = "Yellow", ctermfg = "DarkYellow", cterm = { bold = true } })
hi("Added", { ctermfg = "DarkGreen" })
hi("Changed", { ctermfg = "DarkYellow" })
hi("Removed", { ctermfg = "DarkRed" })

-- Syntax (the core philosophy: bold for structure, color for literals)

-- Default: plain
hi("Identifier", { ctermfg = "NONE" })
hi("Function", { ctermfg = "NONE" })
hi("Delimiter", { ctermfg = "NONE" })
hi("Operator", { ctermfg = "NONE" })
hi("Special", { ctermfg = "NONE" })

-- Comments: grey
hi("Comment", { ctermfg = "DarkGray" })

-- Strings: green
hi("String", { ctermfg = "DarkGreen" })
hi("Character", { ctermfg = "DarkGreen" })

-- Numbers/Constants: yellow
hi("Number", { ctermfg = "DarkYellow" })
hi("Float", { ctermfg = "DarkYellow" })
hi("Boolean", { ctermfg = "DarkYellow" })
hi("Constant", { ctermfg = "DarkYellow" })

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
hi("SpecialChar", { ctermfg = "DarkGreen" })
hi("SpecialComment", { ctermfg = "DarkGray", cterm = { bold = true } })

-- Errors/Todos
hi("Error", { ctermfg = "DarkRed", cterm = { bold = true } })
hi("Todo", { ctermfg = "DarkYellow", cterm = { bold = true } })
hi("Underlined", { cterm = { underline = true } })

-- Treesitter (only overrides, rest falls back to standard groups)
hi("@module", { ctermfg = "NONE" })
hi("@type.definition", { ctermfg = "NONE" })
hi("@string.documentation", { link = "Comment" })
hi("@comment.error", { ctermfg = "DarkRed", cterm = { bold = true } })
hi("@comment.warning", { ctermfg = "DarkYellow", cterm = { bold = true } })
hi("@comment.todo", { ctermfg = "DarkYellow", cterm = { bold = true } })
hi("@comment.note", { ctermfg = "DarkBlue", cterm = { bold = true } })

-- Markup
hi("@markup.strong", { cterm = { bold = true } })
hi("@markup.italic", { cterm = { italic = true } })
hi("@markup.strikethrough", { cterm = { strikethrough = true } })
hi("@markup.underline", { cterm = { underline = true } })
hi("@markup.heading", { cterm = { bold = true } })
hi("@markup.quote", { link = "Comment" })
hi("@markup.link", { cterm = { underline = true } })
hi("@markup.list.checked", { ctermfg = "DarkGreen" })
hi("@markup.list.unchecked", { ctermfg = "DarkRed" })
hi("@markup.raw", { ctermfg = "DarkGray" })

-- Tags (HTML/XML)
hi("@tag", { cterm = { bold = true } })
hi("@tag.attribute", { ctermfg = "NONE" })
hi("@tag.delimiter", { ctermfg = "DarkGray" })

-- Language-specific overrides
hi("@string.yaml", { ctermfg = "NONE" }) -- YAML values are strings but look better plain

-- Diagnostics
hi("DiagnosticError", { ctermfg = "DarkRed" })
hi("DiagnosticWarn", { ctermfg = "DarkYellow" })
hi("DiagnosticInfo", { ctermfg = "DarkBlue" })
hi("DiagnosticHint", { ctermfg = "DarkBlue" })
hi("DiagnosticOk", { ctermfg = "DarkGreen" })

hi("DiagnosticUnderlineError", { cterm = { undercurl = true }, ctermfg = "DarkRed" })
hi("DiagnosticUnderlineWarn", { cterm = { undercurl = true }, ctermfg = "DarkYellow" })
hi("DiagnosticUnderlineInfo", { cterm = { undercurl = true }, ctermfg = "DarkBlue" })
hi("DiagnosticUnderlineHint", { cterm = { undercurl = true }, ctermfg = "DarkBlue" })
hi("DiagnosticUnderlineOk", { cterm = { undercurl = true }, ctermfg = "DarkGreen" })

hi("DiagnosticDeprecated", { cterm = { strikethrough = true } })
hi("DiagnosticUnnecessary", { ctermfg = "DarkGray" })

-- Plugins
hi("GitSignsAdd", { ctermfg = "DarkGreen" })
hi("GitSignsChange", { ctermfg = "DarkYellow" })
hi("GitSignsDelete", { ctermfg = "DarkRed" })

hi("IblIndent", { ctermfg = "DarkGray" })
hi("IblScope", { ctermfg = "NONE" })
