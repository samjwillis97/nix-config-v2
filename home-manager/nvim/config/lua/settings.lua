vim.g.mapleader = "\\"

-- Standard Config
vim.opt.encoding = "utf-8"
vim.opt.errorbells = false
vim.opt.updatetime = 50
vim.opt.shortmess:append("c") -- Why??

-- Swap Files
vim.opt.swapfile = false
vim.opt.dir = "/tmp"

-- Backup Files
vim.opt.backup = false

-- Undo Files
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

-- User Interface
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.cmdheight = 1
vim.opt.signcolumn = "yes"
vim.opt.scrolloff = 8
vim.opt.lazyredraw = true -- Why?
-- vim.opt.showmatch = true -- Why?
vim.opt.termguicolors = true
vim.opt.colorcolumn = "120"

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true

-- Folding
vim.opt.foldenable = true
vim.opt.foldlevelstart = 10
vim.opt.foldnestmax = 10
vim.opt.foldmethod = "indent"

-- Splits
vim.opt.splitbelow = true
vim.opt.splitright = true

-- Trigger autoread when files are updated externallly
vim.opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
	pattern = "*",
	command = "if mode() != 'c' | checktime | endif",
})

-- Remeber Cursor Position
require("nvim-lastplace").setup({})

-- Filetype Settings
vim.api.nvim_create_autocmd("FileType", {
	pattern = "typescript",
	command = "setlocal expandtab tabstop=2 shiftwidth=2 softtabstop=2",
})
vim.api.nvim_create_autocmd("FileType", {
	pattern = "html",
	command = "setlocal expandtab tabstop=2 shiftwidth=2 softtabstop=2",
})

-- Chezmoi
vim.api.nvim_create_autocmd("BufWritePost", {
	pattern = "~/.local/share/chezmoi/*",
	command = 'chezmoi apply --source-path "%"',
})

-- Autoclose VIM if Tree is the last window
vim.api.nvim_create_autocmd("BufEnter", {
	group = vim.api.nvim_create_augroup("NvimTreeClose", { clear = true }),
	pattern = "NvimTree_*",
	callback = function()
		local layout = vim.api.nvim_call_function("winlayout", {})
		if
			layout[1] == "leaf"
			and vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(layout[2]), "filetype") == "NvimTree"
			and layout[3] == nil
		then
			vim.cmd("confirm quit")
		end
	end,
})

-- Reopening A File - at same line (TODO)

-- Insert Mode Remaps
vim.api.nvim_set_keymap("i", "jk", "<Esc>", { noremap = true })

-- Normal Mode Remaps
---- TMUX Sessionizer - overwrites full page down
vim.api.nvim_set_keymap("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>", {})
---- Clear search highlights
vim.api.nvim_set_keymap("n", "<leader><space>", ":nohlsearch<CR>", {})
---- Reload VIMRC
vim.api.nvim_set_keymap("n", "<leader>R", ":source $MYVIMRC<CR>", {})
---- Navigate between splits
vim.api.nvim_set_keymap("n", "<C-J>", "<C-W><C-J>", { noremap = true })
vim.api.nvim_set_keymap("n", "<C-K>", "<C-W><C-K>", { noremap = true })
vim.api.nvim_set_keymap("n", "<C-L>", "<C-W><C-L>", { noremap = true })
vim.api.nvim_set_keymap("n", "<C-H>", "<C-W><C-H>", { noremap = true })
---- Centering after jumps
vim.api.nvim_set_keymap("n", "<C-u>", "<C-u>zz", { noremap = true })
vim.api.nvim_set_keymap("n", "<C-d>", "<C-d>zz", { noremap = true })
vim.api.nvim_set_keymap("n", "<C-i>", "<C-i>zz", { noremap = true })
vim.api.nvim_set_keymap("n", "<C-o>", "<C-o>zz", { noremap = true })
vim.api.nvim_set_keymap("n", "n", "nzz", { noremap = true })
vim.api.nvim_set_keymap("n", "N", "Nzz", { noremap = true })
vim.api.nvim_set_keymap("n", "GG", "GGzz", { noremap = true })
---- Navigate by visual lines
vim.api.nvim_set_keymap("n", "j", "gj", { noremap = true })
vim.api.nvim_set_keymap("n", "k", "gk", { noremap = true })
---- NVIMTree
vim.api.nvim_set_keymap("n", "<C-n>", ":NvimTreeToggle<CR>", { noremap = true })
vim.api.nvim_set_keymap("n", ",n", ":NvimTreeFindFile<CR>", { noremap = true })
---- GitSigns
vim.api.nvim_set_keymap("n", "[g", ":Gitsigns prev_hunk<CR>", { noremap = true })
vim.api.nvim_set_keymap("n", "]g", ":Gitsigns next_hunk<CR>", { noremap = true })
---- Harpoon
vim.api.nvim_set_keymap("n", "<leader>a", ':lua require("harpoon.mark").add_file()<CR>', { noremap = true })
vim.api.nvim_set_keymap("n", "<C-a>", ':lua require("harpoon.ui").toggle_quick_menu()<CR>', { noremap = true })
vim.api.nvim_set_keymap("n", "<leader>1", ':lua require("harpoon.ui").nav_file(1)<CR>', { noremap = true })
vim.api.nvim_set_keymap("n", "<leader>2", ':lua require("harpoon.ui").nav_file(2)<CR>', { noremap = true })
vim.api.nvim_set_keymap("n", "<leader>3", ':lua require("harpoon.ui").nav_file(3)<CR>', { noremap = true })
vim.api.nvim_set_keymap("n", "<leader>4", ':lua require("harpoon.ui").nav_file(4)<CR>', { noremap = true })
---- Telescope
vim.api.nvim_set_keymap("n", "<leader>f", ":Telescope git_files<CR>", { noremap = true })
vim.api.nvim_set_keymap("n", "<leader>F", ":Telescope live_grep<CR>", { noremap = true })
vim.api.nvim_set_keymap("n", "<leader>s", ":Telescope grep_string<CR>", { noremap = true })
vim.api.nvim_set_keymap("n", "<leader>b", ":Telescope buffers<CR>", { noremap = true })
vim.api.nvim_set_keymap("n", "<leader>h", ":Telescope help_tags<CR>", { noremap = true })
vim.api.nvim_set_keymap("n", "<leader>B", ":Telescope current_buffer_fuzzy_find<CR>", { noremap = true })
vim.api.nvim_set_keymap("n", "<leader>d", ":Telescope diagnostics<CR>", { noremap = true })
vim.api.nvim_set_keymap("n", "gd", ":Telescope lsp_definitions<CR>", { noremap = true })
vim.api.nvim_set_keymap("n", "gr", ":Telescope lsp_references<CR>", { noremap = true })
vim.api.nvim_set_keymap("n", "gi", ":Telescope lsp_implementations<CR>", { noremap = true })
vim.api.nvim_set_keymap("n", "<leader>o", ":SymbolsOutline<CR>", { noremap = true })
---- LSP
---- Code Navigation + LSP
vim.keymap.set("n", "<space>e", vim.diagnostic.open_float, { noremap = true })
vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist, { noremap = true })
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { noremap = true })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { noremap = true })
vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist, { noremap = true })
