local utils = require("smart-im.utils")

local switched_to_target = false

local M = {
	previous_im = "",
	input_detect = 0,
}

---@class SetupConfig
---@field override_cmd string|nil
---@field sync boolean
---@field enter_insert_mode string|(fun(): string)
---@field back_normal_mode fun(M.previous_im: string): string
---@field allow_changing_im fun(node: TSNode|nil): boolean
---@field max_detect_input_count number
---@field ft string[]|nil
---@field ignore_ft string[]|nil

---@param config SetupConfig
function M.setup(config)
	if not utils.is_supported() then
		vim.notify("[smart-im]: no input method switch command found for this OS", vim.log.levels.WARN)
		return
	end

	local cmd = config.override_cmd or utils.pick_default_cmd()

	local enter_insert_mode = config.enter_insert_mode
		or function()
			-- rv[1] is current im used for restoring it while switch back to NORMAL mode
			-- rv[2] is target im
			return { utils.get_current_select(cmd), "com.apple.keylayout.ABC" }
		end

	local back_normal_mode = config.back_normal_mode
		or function()
			return M.previous_im or "com.apple.keylayout.ABC"
		end

	local autocmd_group = vim.api.nvim_create_augroup("smart-im", { clear = true })
	local pattern = config.ft or { "*" }
	local allow_changing_im = config.allow_changing_im or utils.allow_changing_im
	local switch_to_target = function()
		if
			utils.is_ignore_ft(config.ignore_ft or {})
			or switched_to_target
			or not allow_changing_im(utils.get_current_ts_node())
		then
			return
		end

		local eim_rv = type(enter_insert_mode) == "function" and enter_insert_mode() or enter_insert_mode
		local eim_rv_arr = {}

		if type(eim_rv) == "table" then
			if #eim_rv == 2 and not eim_rv[1] and not eim_rv[2] then
				vim.notify("[smart-im]: return value of `enter_insert_mode` is invalid", vim.log.levels.WARN)
				return
			end
			eim_rv_arr = eim_rv
		elseif type(eim_rv) == "string" then
			eim_rv_arr = { utils.get_current_select(cmd), eim_rv }
		else
			vim.notify("[smart-im]: return value of `enter_insert_mode` is invalid", vim.log.levels.WARN)
		end

		M.previous_im = eim_rv_arr[1]
		utils.change_im(cmd, eim_rv_arr[2], not config.sync)
		switched_to_target = true
	end
	local switch_back = function()
		if utils.is_ignore_ft(config.ignore_ft or {}) then
			return
		end

		local bnm_rv = back_normal_mode(M.previous_im)

		if not bnm_rv then
			vim.notify("[smart-im]: return value of `back_normal_mode` is invalid", vim.log.levels.WARN)
			return
		end

		-- restore im when before insert mode
		utils.change_im(cmd, bnm_rv, not config.sync)
		switched_to_target = false
		M.previous_im = ""
		M.input_detect = 0
	end
	local max_detect_input_count = config.max_detect_input_count or 5

	vim.api.nvim_create_autocmd({ "InsertEnter" }, {
		group = autocmd_group,
		pattern = pattern,
		callback = switch_to_target,
	})

	vim.api.nvim_create_autocmd({ "TextChangedI" }, {
		group = autocmd_group,
		pattern = pattern,
		callback = function()
			if M.input_detect >= max_detect_input_count then
				return
			end

			M.input_detect = M.input_detect + 1
			switch_to_target()
		end,
	})

	vim.api.nvim_create_autocmd({ "InsertLeave", "TermLeave", "FocusGained", "VimEnter", "CmdlineLeave" }, {
		group = autocmd_group,
		pattern = pattern,
		callback = switch_back,
	})
end

return M
