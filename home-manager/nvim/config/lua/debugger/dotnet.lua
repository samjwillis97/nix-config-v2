local dap = require("dap")
dap.adapters.coreclr = {
	type = "executable",
	command = { os.getenv("HOME") .. "/.local/share/nvim/mason/packages/netcoredbg/netcoredbg" },
	args = { "--interpreter=vscode" },
}

dap.configurations.cs = {
	{
		type = "coreclr",
		name = "launch - netcoredbg",
		request = "launch",
		program = function()
			return vim.fn.input("Path to dll", vim.fn.getcwd() .. "/bin/Debug/", "file")
		end,
	},
}
