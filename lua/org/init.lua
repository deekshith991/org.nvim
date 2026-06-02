-- Simple debug print when the plugin file is loaded
print("hello from org plugin")

local M = {}

-- Utility: expands ~ to HOME directory
local function expand_path(path)
	-- If path starts with "~", replace it with HOME env var
	if path:sub(1, 1) == "~" then
		return os.getenv("HOME") .. path:sub(2)
	end
	-- Otherwise return unchanged path
	return path
end

-- Computes centered floating window configuration
local function win_config()
	-- Calculate width as 80% of editor width, max 64 columns
	local width = math.min(math.floor(vim.o.columns * 0.8), 64)

	-- Calculate height as 80% of editor height, leaving 4 lines margin
	local height = math.min(math.floor(vim.o.lines * 0.8), vim.o.lines - 4)

	-- Return floating window configuration table
	return {
		relative = "editor",
		width = width,
		height = height,
		col = math.floor((vim.o.columns - width) / 2),
		row = math.floor((vim.o.lines - height) / 2),
		border = "single",
	}
end

--[[ 
-- (Disabled feature)
-- Toggles line numbers and relative numbers for a buffer
-- local function toggle_numbers()
-- 	local nu = vim.api.nvim_get_option_value("number", { buf = buf })
-- 	local rnu = vim.api.nvim_get_option_value("relativenumber", { buf = buf })
--
-- 	vim.api.nvim_set_option_value("number", not nu, { buf = buf })
-- 	vim.api.nvim_set_option_value("relativenumber", not rnu, { buf = buf })
-- end
]]

-- Toggle markdown task under cursor and append date when completing
local function toggleTask()
	local line = vim.api.nvim_get_current_line()

	-- Match:
	-- indent + (- or *) + [ ]/[x]
	local indent, bullet, box, rest = line:match("^(%s*)([-*])%s%[([ xX])%]%s(.*)$")

	if not indent then
		vim.notify("Not a markdown task", vim.log.levels.INFO)
		return
	end

	local date = os.date("%Y-%m-%d")

	if box == " " then
		-- complete task
		line = string.format("%s%s [x] %s ✔ %s", indent, bullet, rest, date)
	else
		-- reopen task (remove checkbox + date safely)
		rest = rest:gsub("%s+✔%s+%d%d%d%d%-%d%d%-%d%d", "")
		line = string.format("%s%s [ ] %s", indent, bullet, rest)
	end

	vim.api.nvim_set_current_line(line)
end

-- Add a new markdown task based on previous line indentation
-- and immediately enter insert mode
local function addTask()
	local buf = vim.api.nvim_get_current_buf()
	local row = vim.api.nvim_win_get_cursor(0)[1]

	-- Get previous line
	local prev_line = vim.api.nvim_buf_get_lines(buf, row - 2, row - 1, false)[1]

	-- Default task if no previous line
	if not prev_line then
		vim.api.nvim_put({ "- [ ] " }, "c", true, true)
		vim.cmd("startinsert!")
		return
	end

	-- Preserve indentation from previous line
	local indent = prev_line:match("^(%s*)") or ""

	-- Insert new task line
	local new_line = indent .. "- [ ] "

	vim.api.nvim_put({ new_line }, "c", true, true)

	-- Move cursor to end of inserted line
	vim.api.nvim_win_set_cursor(0, {
		vim.api.nvim_win_get_cursor(0)[1],
		#new_line,
	})

	-- Enter insert mode
	vim.cmd("startinsert!")
end

-- Opens a TODO file inside a floating window
local function open_floating_file(todo_file)
	-- Check if file exists before opening
	if vim.fn.filereadable(todo_file) == 0 then
		vim.notify("TODO file doesn't exist at " .. todo_file, vim.log.levels.ERROR)
		return
	end

	-- Get or create buffer for the file
	local buf = vim.fn.bufnr(todo_file, true)

	-- Disable swapfile for this buffer
	vim.bo[buf].swapfile = false

	-- Open floating window with buffer
	local win = vim.api.nvim_open_win(buf, true, win_config())

	-- Disable line numbers in floating window
	vim.wo[win].number = false
	vim.wo[win].relativenumber = false

	-- Ensure buffer is displayed
	vim.cmd("buffer " .. buf)

	-- Keymap: quit window with 'q'
	vim.api.nvim_buf_set_keymap(buf, "n", "q", "", {
		noremap = true,
		silent = true,
		callback = function()
			-- Prevent closing if buffer has unsaved changes
			if vim.api.nvim_get_option_value("modified", { buf = buf }) then
				vim.notify("Save the changes", vim.log.levels.WARN)
			else
				vim.api.nvim_win_close(0, true)
			end
		end,
	})

	-- Keymap: toggle line numbers with 's'
	vim.api.nvim_buf_set_keymap(buf, "n", "s", "", {
		noremap = true,
		silent = true,
		callback = function()
			-- Get current window
			local win = vim.api.nvim_get_current_win()

			-- Read current number settings
			local nu = vim.wo[win].number
			local rnu = vim.wo[win].relativenumber

			-- Toggle number and relative number
			vim.wo[win].number = not nu
			vim.wo[win].relativenumber = not rnu
		end,
	})

	vim.api.nvim_buf_set_keymap(buf, "n", "tt", "", {
		noremap = true,
		silent = true,
		callback = function()
			toggleTask()
		end,
	})

	vim.api.nvim_buf_set_keymap(buf, "n", "a", "", {
		noremap = true,
		silent = true,
		callback = function()
			addTask()
		end,
	})
end

-- Sets up user-facing Neovim commands for the plugin
local function setup_user_commands(opts)
	-- Resolve todo file path from config or default
	local todo_file = expand_path(opts.todo_file or "~/notes/todo.md")

	-- Debug command: prints resolved todo file path
	-- NOTE: intended for development only
	vim.api.nvim_create_user_command("Dumpopts", function()
		print(todo_file)
	end, {
		desc = "Dump plugin Config",
	})

	-- Main command: opens todo file in floating window
	vim.api.nvim_create_user_command("TodoView", function()
		open_floating_file(todo_file)
	end, { desc = "Open todo file in a floating window" })
end

-- Plugin entry point
function M.setup(opts)
	setup_user_commands(opts or {})

	-- Keymap: <leader>td opens TodoView floating window
	vim.keymap.set("n", "<leader>td", function()
		vim.cmd("TodoView")
	end, { desc = "Open TODO view" })
end

return M
