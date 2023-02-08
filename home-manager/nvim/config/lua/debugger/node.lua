local dap = require("dap")
dap.adapters.node2 = {
	type = "executable",
	command = "node",
	-- Assuming this is installed via Mason
	args = { os.getenv("HOME") .. "/.local/share/nvim/mason/packages/node-debug2-adapter/out/src/nodeDebug.js" },
}

dap.adapters.firefox = {
	type = "executable",
	command = "node",
	-- Assuming this is installed via Mason
	args = { os.getenv("HOME") .. "/.local/share/nvim/mason/packages/firefox-debug-adapter/dist/adapter.bundle.js" },
}

dap.configurations.typescript = {
	{
		name = "Attach to process",
		type = "node2",
		request = "attach",
		processId = require("dap.utils").pick_process,
	},
	{
		name = "Debug with Firefox",
		type = "firefox",
		request = "launch",
		reAttach = true,
		url = "http://localhost:4200",
		webRoot = "${workspaceFolder}",
		firefoxExecutable = "/usr/bin/firefox",
	},
}
