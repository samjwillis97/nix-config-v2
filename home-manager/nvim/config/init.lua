require("packages")
require("lsp")
require("treesitter")
require("filetree")
require("statusline")
require("telescope-settings")
require("outline")
require("debugger")
require("format")
require("settings")

vim.g.catppuccin_flavour = "macchiato"
require("catppuccin").setup({
	compile_path = "~/.local/share/nvim/color",
})
vim.cmd([[colorscheme catppuccin]])
require("colorizer").setup()
