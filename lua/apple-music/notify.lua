local M = {}

--- Notifies the user with a error message
--- @param message string Message to display
M.error = function(message)
	vim.notify(message, vim.log.levels.ERROR, {
		title = "apple-music.nvim",
	})
end

return M
