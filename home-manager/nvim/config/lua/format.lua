-- Utilities for creating configurations
local util = require("formatter.util")

-- Format on Save
-- Trying to write a function to save the buffer cursor positions before formatwrite and restores after
-- https://github.com/mhartington/formatter.nvim/issues/197
local formatGroup = vim.api.nvim_create_augroup("FormatAutogroup", { clear = true })
vim.api.nvim_create_autocmd("BufWritePost", {
	command = "FormatWrite",
	-- callback = function()
	-- 	local buf = vim.fn.expand("<abuf>")
	-- 	print(buf)
	-- 	print(vim.inspect(vim.fn.getbufinfo()))
	-- end,
	pattern = "*",
	group = formatGroup,
})

-- Provides the Format, FormatWrite, FormatLock, and FormatWriteLock commands
require("formatter").setup({
	filetype = {
		go = {
			-- gofumpt
			function()
				return {
					exe = "gofumpt",
					args = {},
					stdin = true,
				}
			end,
		},
		cs = {
			require("formatter.filetypes.cs").dotnetformat,
		},
		typescript = {
			require("formatter.filetypes.typescript").prettier,
		},
		javascript = {
			require("formatter.filetypes.javascript").prettier,
		},
		svelte = {
			require("formatter.filetypes.svelte").prettier,
		},
		json = {
			require("formatter.filetypes.json").prettier,
		},
		yaml = {
			require("formatter.filetypes.yaml").prettier,
		},
		python = {
			require("formatter.filetypes.python").black,
		},
		html = {
			require("formatter.filetypes.html").prettier,
		},
		lua = {
			require("formatter.filetypes.lua").stylua,
		},
		rust = {
			require("formatter.filetypes.rust").rustfmt,
		},
	},
})
