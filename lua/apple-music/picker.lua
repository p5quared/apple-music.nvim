local M = {}

local notify = require("apple-music.notify")

--- Use telescope to pick an item from a list
--- @param pickers table Telescope pickers module
--- @param title string Title of the picker
--- @param items table List of items to pick from
--- @param on_select function(item: string) Function to call when an item is selected
local function telescope_pick(pickers, title, items, on_select)
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	pickers
		.new({}, {
			prompt_title = title,
			finder = finders.new_table({
				results = items,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr, _)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					on_select(selection[1])
				end)
				return true
			end,
		})
		:find()
end

--- Use fzf-lua to pick an item from a list
--- @param fzf_lua table Fzf-lua module
--- @param title string Title of the picker
--- @param items table List of items to pick from
--- @param on_select function(item: string) Function to call when an item is selected
local function fzf_lua_pick(fzf_lua, title, items, on_select)
	fzf_lua.fzf_exec(items, {
		prompt = title .. "> ",
		actions = {
			["default"] = function(selected)
				on_select(selected[1])
			end,
		},
	})
end

--- @alias Picker "auto" | "telescope" | "fzf-lua" | "select"

--- Pick an item from a list
--- If telescope is available, it will be used to pick the item
--- Otherwise, `vim.ui.select` will be used
--- @param picker Picker Title of the picker
--- @param title string Title of the picker
--- @param items table List of items to pick from
--- @param on_select function(item: string) Function to call when an item is selected
M.pick = function(picker, title, items, on_select)
	if picker == "auto" or picker == "telescope" then
		local telescope_exists, telescope_pickers = pcall(require, "telescope.pickers")
		if telescope_exists then
			telescope_pick(telescope_pickers, title, items, on_select)
			return
		end

		-- If the picker is not "auto", we don't want to fall back to vim.ui.select
		if picker == "telescope" then
			notify.error("Telescope not found. Install Telescope or change the picker.")
			return
		end
	end

	if picker == "auto" or picker == "fzf-lua" then
		local fzf_lua_exists, fzf_lua = pcall(require, "fzf-lua")
		if fzf_lua_exists then
			fzf_lua_pick(fzf_lua, title, items, on_select)
			return
		end

		-- If the picker is not "auto", we don't want to fall back to vim.ui.select
		if picker == "fzf-lua" then
			notify.error("Fzf-lua not found. Install Fzf-lua or change the picker.")
			return
		end
	end

	if picker == "auto" or picker == "select" then
		vim.ui.select(items, {
			prompt = title,
		}, function(item)
			if item then
				on_select(item)
			end
		end)
		return
	end

	notify.error("Unknown picker: " .. picker .. ". Available pickers: auto, telescope, fzf-lua, select")
end

return M
