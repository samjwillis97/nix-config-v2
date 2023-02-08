local dap = require("dap")
local dapui = require("dapui")
require("nvim-dap-virtual-text").setup({
	-- commented = true,
})

require("debugger.python")
require("debugger.go")
require("debugger.node")
require("debugger.dotnet")
-- require("debugger.rust")

dapui.setup({
	mappings = {
		open = { "zo" },
		close = { "zc" },
		remove = "d",
		edit = "e",
		repl = "r",
		toggle = "t",
	},
	layouts = {
		{
			elements = {
				-- Elements can be strings or table with id and size keys.
				{ id = "scopes", size = 0.5 },
				"breakpoints",
				"watches",
				"stacks",
			},
			size = 50, -- 50 columns
			position = "left",
		},
		{
			elements = {
				"repl",
				"console",
			},
			size = 0.25, -- 25% of total lines
			position = "bottom",
		},
	},
	controls = {
		enabled = true,
		elements = "repl",
	},
})

dap.listeners.after.event_initialized["dapui_config"] = function()
	dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
	dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
	dapui.close()
end

vim.api.nvim_set_keymap("n", "<Leader>D", ":lua require'dap'.run()<CR>", { noremap = true })
vim.api.nvim_set_keymap("n", "<Leader><Leader>", ":lua require'dap'.terminate()<CR>", { noremap = true })

vim.api.nvim_set_keymap("n", "<Up>", ":lua require'dap'.continue()<CR>", { noremap = true })
vim.api.nvim_set_keymap("n", "<Down>", ":lua require'dap'.step_over()<CR>", { noremap = true })
vim.api.nvim_set_keymap("n", "<Right>", ":lua require'dap'.step_into()<CR>", { noremap = true })
vim.api.nvim_set_keymap("n", "<Left>", ":lua require'dap'.step_out()<CR>", { noremap = true })

vim.api.nvim_set_keymap("n", "<Leader>BB", ":lua require'dap'.toggle_breakpoint()<CR>", { noremap = true })
vim.api.nvim_set_keymap(
	"n",
	"<Leader>BC",
	":lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>",
	{ noremap = true }
)
vim.api.nvim_set_keymap("n", "<Leader>rc", ":lua require'dap'.run_to_cursor()<CR>", { noremap = true })
