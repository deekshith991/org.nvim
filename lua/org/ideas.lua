local M = {}

----------------------------------------------------------------------
-- Scan a directory and return sorted items
--
-- Directories are listed first, then files.
----------------------------------------------------------------------
local function scandir(path)
	local items = {}

	local handle = vim.loop.fs_scandir(path)
	if not handle then
		return items
	end

	while true do
		local name, typ = vim.loop.fs_scandir_next(handle)

		if not name then
			break
		end

		table.insert(items, {
			name = name,
			type = typ,
		})
	end

	table.sort(items, function(a, b)
		if a.type == b.type then
			return a.name < b.name
		end

		return a.type == "directory"
	end)

	return items
end

----------------------------------------------------------------------
-- Toggle line numbers
--
-- States:
--   ON  -> number + relativenumber
--   OFF -> no number + no relativenumber
----------------------------------------------------------------------
local function toggle_line_numbers(win)
	local number = vim.wo[win].number
	local relativenumber = vim.wo[win].relativenumber

	if number or relativenumber then
		vim.wo[win].number = false
		vim.wo[win].relativenumber = false
	else
		vim.wo[win].number = true
		vim.wo[win].relativenumber = true
	end
end

----------------------------------------------------------------------
-- Open a file inside a floating editor window.
--
-- This is used for:
--   1. Opening existing files
--   2. Opening newly created files
--
-- The float is centered and occupies ~80% of the screen.
----------------------------------------------------------------------
local function open_file_in_float(filepath)
	-- Create/load buffer for the file
	local buf = vim.fn.bufadd(filepath)
	vim.fn.bufload(buf)

	-- Buffer options
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false

	-- Float size
	local width = math.floor(vim.o.columns * 0.8)
	local height = math.floor(vim.o.lines * 0.8)

	-- Center the window
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		border = "rounded",
		style = "minimal",
	})

	-- Make sure cursor enters the floating window
	vim.api.nvim_set_current_win(win)

	------------------------------------------------------------------
	-- Close floating editor
	--
	-- Prevent closing if buffer has unsaved changes.
	------------------------------------------------------------------
	vim.keymap.set("n", "q", function()
		if not vim.api.nvim_win_is_valid(win) then
			return
		end

		if vim.bo[buf].modified then
			vim.notify("Buffer has unsaved changes. Save (:w) before closing.", vim.log.levels.WARN)
			return
		end

		vim.api.nvim_win_close(win, false)
	end, {
		buffer = buf,
		silent = true,
		nowait = true,
	})

	------------------------------------------------------------------
	-- Save file
	------------------------------------------------------------------
	vim.keymap.set("n", "<C-s>", function()
		vim.cmd("write")
	end, {
		buffer = buf,
		silent = true,
		desc = "Save file",
	})

	vim.keymap.set("n", "w", function()
		vim.cmd("write")
	end, {
		buffer = buf,
		silent = true,
		desc = "Save file",
	})

	------------------------------------------------------------------
	-- Toggle line numbers with 's'
	------------------------------------------------------------------
	vim.keymap.set("n", "s", function()
		if vim.api.nvim_win_is_valid(win) then
			toggle_line_numbers(win)
		end
	end, {
		buffer = buf,
		silent = true,
		nowait = true,
		desc = "Toggle line numbers",
	})
end

----------------------------------------------------------------------
-- Main file explorer UI
----------------------------------------------------------------------
function M.open(path)
	local items = scandir(path)

	local lines = {}

	for _, item in ipairs(items) do
		if item.type == "directory" then
			table.insert(lines, "📁 " .. item.name)
		else
			table.insert(lines, "📄 " .. item.name)
		end
	end

	table.insert(lines, "")
	table.insert(lines, "[n] New file")

	-- Create explorer buffer
	local buf = vim.api.nvim_create_buf(false, true)

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	------------------------------------------------------------------
	-- Explorer floating window
	------------------------------------------------------------------
	local width = 60
	local height = math.min(#lines + 2, 20)

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = 3,
		col = 10,
		border = "rounded",
		style = "minimal",
	})

	------------------------------------------------------------------
	-- Open selected item
	------------------------------------------------------------------
	local function open_selected()
		local row = vim.api.nvim_win_get_cursor(win)[1]
		local item = items[row]

		if not item then
			return
		end

		local fullpath = path .. "/" .. item.name

		if item.type == "directory" then
			-- Navigate into directory
			vim.api.nvim_win_close(win, true)
			M.open(fullpath)
		else
			-- Open file in floating editor
			vim.api.nvim_win_close(win, true)
			open_file_in_float(fullpath)
		end
	end

	------------------------------------------------------------------
	-- Create a new markdown file
	------------------------------------------------------------------
	local function new_file()
		vim.ui.input({
			prompt = "New file name: ",
		}, function(name)
			if not name or name == "" then
				return
			end

			----------------------------------------------------------
			-- Auto-add .md extension if none provided
			----------------------------------------------------------
			if not name:match("%.[^%.]+$") then
				name = name .. ".md"
			end

			local filepath = path .. "/" .. name

			----------------------------------------------------------
			-- Metadata values
			----------------------------------------------------------
			local title = vim.fn.fnamemodify(name, ":t:r")
			local heading = title:gsub("[-_]", " ")

			local timestamp = os.date("%Y-%m-%d %H:%M:%S")

			----------------------------------------------------------
			-- Markdown template
			----------------------------------------------------------
			local content = string.format(
				[[---
Title: %s
Author: deekshith
Created: %s
Modified: %s
Tags: []
---

# %s

]],
				title,
				timestamp,
				timestamp,
				heading
			)

			local fd = io.open(filepath, "w")

			if not fd then
				vim.notify("Failed to create file: " .. filepath, vim.log.levels.ERROR)
				return
			end

			fd:write(content)
			fd:close()

			----------------------------------------------------------
			-- Close explorer and open newly created file
			-- in a floating editor window
			----------------------------------------------------------
			vim.api.nvim_win_close(win, true)
			open_file_in_float(filepath)
		end)
	end

	------------------------------------------------------------------
	-- Explorer keymaps
	------------------------------------------------------------------
	vim.keymap.set("n", "<CR>", open_selected, {
		buffer = buf,
		silent = true,
	})

	vim.keymap.set("n", "n", new_file, {
		buffer = buf,
		silent = true,
	})

	vim.keymap.set("n", "q", function()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end, {
		buffer = buf,
		silent = true,
	})
end

return M
