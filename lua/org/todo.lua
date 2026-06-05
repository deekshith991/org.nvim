local M = {}

-- Floating window config
local function win_config(filepath)
	local width = math.min(math.floor(vim.o.columns * 0.8), 64)
	local height = math.min(math.floor(vim.o.lines * 0.8), vim.o.lines - 4)

	return {
		relative = "editor",
		width = width,
		height = height,
		col = math.floor((vim.o.columns - width) / 2),
		row = math.floor((vim.o.lines - height) / 2),
		border = "rounded",
		title = " " .. vim.fn.fnamemodify(filepath, ":t") .. " ",
		title_pos = "center",
		style = "minimal",
	}
end

---------------------------------------------------
-- TASK TOGGLE
---------------------------------------------------
local function toggleTask()
	local line = vim.api.nvim_get_current_line()

	local indent, bullet, box, rest = line:match("^(%s*)([-*])%s%[([ xX])%]%s(.*)$")

	if not indent then
		vim.notify("Not a markdown task", vim.log.levels.INFO)
		return
	end

	local date = os.date("%Y-%m-%d")

	if box == " " then
		line = string.format("%s%s [x] %s ✔ %s", indent, bullet, rest, date)
	else
		rest = rest:gsub("%s+✔%s+%d%d%d%d%-%d%d%-%d%d", "")
		line = string.format("%s%s [ ] %s", indent, bullet, rest)
	end

	vim.api.nvim_set_current_line(line)
end

---------------------------------------------------
-- ADD TASK
---------------------------------------------------
local function addTask()
	local buf = vim.api.nvim_get_current_buf()
	local row = vim.api.nvim_win_get_cursor(0)[1]

	local prev_line = vim.api.nvim_buf_get_lines(buf, row - 2, row - 1, false)[1]

	local indent = ""
	if prev_line then
		indent = prev_line:match("^(%s*)") or ""
	end

	local new_line = indent .. "- [ ] "

	vim.api.nvim_put({ new_line }, "c", true, true)
	vim.cmd("startinsert!")
end

---------------------------------------------------
-- FLOATING WINDOW
---------------------------------------------------
local function attach_keymaps(buf)
	vim.api.nvim_buf_set_keymap(buf, "n", "q", "", {
		noremap = true,
		silent = true,
		callback = function()
			if vim.api.nvim_get_option_value("modified", { buf = buf }) then
				vim.notify("Save the changes", vim.log.levels.WARN)
			else
				vim.api.nvim_win_close(0, true)
			end
		end,
	})

	vim.api.nvim_buf_set_keymap(buf, "n", "s", "", {
		noremap = true,
		silent = true,
		callback = function()
			local win = vim.api.nvim_get_current_win()
			vim.wo[win].number = not vim.wo[win].number
			vim.wo[win].relativenumber = not vim.wo[win].relativenumber
		end,
	})

	vim.api.nvim_buf_set_keymap(buf, "n", "x", "", {
		noremap = true,
		silent = true,
		callback = toggleTask,
	})

	vim.api.nvim_buf_set_keymap(buf, "n", "z", "", {
		noremap = true,
		silent = true,
		callback = addTask,
	})
end

function M.open(todo_file)
	if vim.fn.filereadable(todo_file) == 0 then
		vim.notify("TODO file doesn't exist at " .. todo_file, vim.log.levels.ERROR)
		return
	end

	local buf = vim.fn.bufnr(todo_file, true)

	vim.bo[buf].swapfile = false

	local win = vim.api.nvim_open_win(buf, true, win_config(todo_file))

	vim.wo[win].number = false
	vim.wo[win].relativenumber = false

	vim.cmd("buffer " .. buf)

	attach_keymaps(buf)
end

return M
