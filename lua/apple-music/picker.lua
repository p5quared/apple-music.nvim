local M = {}

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
        attach_mappings = function(prompt_bufnr, map)
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

--- Pick an item from a list
--- If telescope is available, it will be used to pick the item
--- Otherwise, `vim.ui.select` will be used
--- @param title string Title of the picker
--- @param items table List of items to pick from
--- @param on_select function(item: string) Function to call when an item is selected
M.pick = function(title, items, on_select)
  local telescope_exists, telescope_pickers = pcall(require, 'telescope.pickers')
  if telescope_exists then
    telescope_pick(telescope_pickers, title, items, on_select)
    return
  end

  vim.ui.select(items, {
    prompt = title
  }, function(item)
    if item then
      on_select(item)
    end
  end)
end

return M
