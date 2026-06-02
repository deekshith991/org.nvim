local todo = require("org.todo")

local M = {}

-- Utility: expands ~ to HOME directory
local function expand_path(path)
	if path:sub(1, 1) == "~" then
		return os.getenv("HOME") .. path:sub(2)
	end
	return path
end

-- Setup plugin
function M.setup(opts)
	opts = opts or {}

	local todo_file = expand_path(opts.todo_file or "~/notes/todo.md")

	-- Create user command
	vim.api.nvim_create_user_command("TodoView", function()
		todo.open(todo_file)
	end, { desc = "Open todo file in floating window" })

	-- Debug command
	vim.api.nvim_create_user_command("Dumpopts", function()
		print(todo_file)
	end, { desc = "Dump plugin config" })

	-- Keymap
	vim.keymap.set("n", "<leader>td", function()
		vim.cmd("TodoView")
	end, { desc = "Open TODO view" })
end

return M
