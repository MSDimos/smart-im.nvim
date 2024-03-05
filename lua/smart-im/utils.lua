local M = {}

local function all_trim(s)
	return s:match("^%s*(.-)%s*$")
end

M.supported_cmds = {
	-- macism is the only choice!
	MacOS = { "macism" },
	Windows = { "im-select" },
	WSL = { "im-select" },
	-- Support fcitx5, fcitx and ibus in Linux
	Linux = { "fcitx5-remote", "fcitx-remote", "ibus" },
}

-- fork from https://github.com/keaising/im-select.nvim/blob/master/lua/im_select.lua#L9
function M.determine_os()
	if vim.fn.has("macunix") == 1 then
		return "MacOS"
	elseif vim.fn.has("win32") == 1 then
		return "Windows"
	elseif vim.fn.has("wsl") == 1 then
		return "WSL"
	else
		return "Linux"
	end
end

-- fork from https://github.com/keaising/im-select.nvim/blob/master/lua/im_select.lua#L21
function M.is_supported()
	local os = M.determine_os()
	local ims = M.supported_cmds[os] or {}

	for _, im in ipairs(ims) do
		if vim.fn.executable(im) then
			return true
		end
	end
end

-- fork from https://github.com/keaising/im-select.nvim/blob/master/lua/im_select.lua#L119C1-L129C4
function M.get_current_select(cmd)
	local command = {}
	if cmd:find("fcitx5-remote", 1, true) ~= nil then
		command = { cmd, "-n" }
	elseif cmd:find("ibus", 1, true) ~= nil then
		command = { cmd, "engine" }
	else
		command = { cmd }
	end
	return all_trim(vim.fn.system(command))
end

function M.change_im(cmd, method, async_switch_im)
	local args = {}
	if cmd:find("fcitx5-remote", 1, true) then
		args = { "-s", method }
	elseif cmd:find("fcitx-remote", 1, true) then
		-- limited support for fcitx, can only switch for inactive and active
		if method == "1" then
			method = "-c"
		else
			method = "-o"
		end
		args = { method }
	elseif cmd:find("ibus", 1, true) then
		args = { "engine", method }
	else
		args = { method }
	end

	local handle
	handle, _ = vim.loop.spawn(
		cmd,
		{ args = args, detach = true },
		vim.schedule_wrap(function(_, _)
			if handle and not handle:is_closing() then
				handle:close()
			end
			M.closed = true
		end)
	)
	if not handle then
		vim.api.nvim_err_writeln([[[smart-im]: Failed to spawn process for ]] .. cmd)
	end

	if not async_switch_im then
		vim.wait(5000, function()
			return M.closed
		end, 200)
	end
end

function M.pick_default_cmd()
	local os = M.determine_os()
	local ims = M.supported_cmds[os] or {}

	for _, im in ipairs(ims) do
		if vim.fn.executable(im) then
			return im
		end
	end
end

---@param ignore_ft string[]
function M.is_ignore_ft(ignore_ft)
	local current_ft = vim.bo.filetype

	for _, ft in ipairs(ignore_ft) do
		if ft == current_ft then
			return true
		end
	end

	return false
end

function M.get_current_ts_node()
	local has_parser = require("nvim-treesitter.parsers").has_parser()

	if not has_parser then
		return nil
	end

	local cursor = vim.api.nvim_win_get_cursor(0)
	local pos = { cursor[1] - 1, cursor[2] == 0 and 0 or cursor[2] - 1 }
	local node = vim.treesitter.get_node({ pos = pos })

	return node
end

-- for default, it will detect if there is none-ascii char in comment and literal string
-- 1. if it has onne-ascii chars in which, it will switch IM
-- 2. if it's empty comment, it will switch IM
-- 3. if it's consists of ascii chars, it will NOT switch
---@param node TSNode|nil
function M.allow_changing_im(node)
	if node and node:type() then
		if node:type():match("comment") or node:type():match("string") then
			local start_row, start_col, end_row, end_col = node:range()
			local node_content = table.concat(vim.api.nvim_buf_get_text(0, start_row, start_col, end_row, end_col, {}))
			local none_ascii_pattern = "[^%z\1-\127]"
			local only_symbol_pattern = "^[%p%s]+$"

			local has_none_ascii = not not string.match(node_content, none_ascii_pattern)
			local only_symbol = not not string.match(node_content, only_symbol_pattern)

			if node:type():match("string") then
				return #node_content > 0 and (only_symbol or has_none_ascii)
			end

			return #node_content == 0 or only_symbol or has_none_ascii
		end
	end

	return false
end

return M
