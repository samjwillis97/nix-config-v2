require'nvim-treesitter.configs'.setup {
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
  indent = {
    enable = true,
    disable = {},
  },
  ensure_installed = {
		"json",
		"jsonc",
		"yaml",
		"toml",
		"lua",
		"go",
		"typescript",
		"javascript",
		"python",
		"rust",
		"c_sharp",
		"svelte",
		"vue",
		"css",
		"html",
        "nix",
  },
  sync_install = false,
  parser_install_dir = "~/.local/share/nvim/site/",
}

vim.opt.runtimepath:append("~/.local/share/nvim/site/")

function ContextSetup(show_all_context)
    require("treesitter-context").setup({
        enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
        throttle = true, -- Throttles plugin updates (may improve performance)
        max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
        show_all_context = show_all_context,
        patterns = { -- Match patterns for TS nodes. These get wrapped to match at word boundaries.
            -- For all filetypes
            -- Note that setting an entry here replaces all other patterns for this entry.
            -- By setting the 'default' entry below, you can control which nodes you want to
            -- appear in the context window.
            default = {
                "function",
                "method",
                "for",
                "while",
                "if",
                "switch",
                "case",
            },

            rust = {
                "loop_expression",
                "impl_item",
            },

            typescript = {
                "class_declaration",
                "abstract_class_declaration",
                "else_clause",
            },
        },
    })
end

vim.opt.list = true
-- vim.opt.listchars:append "space:"
-- vim.opt.listchars:append "eol:↴"

require("indent_blankline").setup {
}
