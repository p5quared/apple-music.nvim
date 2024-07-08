local pickers = require("telescope.pickers")
local conf = require("telescope.config").values
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local function execute_applescript(script)
	local command = 'osascript -e \'' .. script .. '\''
	local handle = io.popen(command)
	local result = handle:read("*a")
	handle:close()
	return result
end

local am_run = function(cmd)
	local script = 'tell application "Music" to ' .. cmd
	return execute_applescript(script)
end

local am_app_run = function(cmd)
	local script = 'tell app "Music" to ' .. cmd
	return execute_applescript(script)
end

local execute = function(cmd)
	local exe = function(cmd)
		local handle = io.popen(cmd)
		local result = handle:read("*a")
		handle:close()
		return result
	end
	return pcall(exe, cmd)
end

local M = {}

M.setup = function()
	print('apple music loaded')
end

M.temp_playlist_name = "nvim_apple_music"

-- NOTE: Requires the song to be a valid title (not fuzzy)
M.play_track = function(track)
	print("Playing " .. track)
	local command = string.format([[
        osascript -e '
        tell application "Music"
            play track "%s"
        end tell'
    ]], track)

	local result = execute(command)

	if result then
		print("Successfully played: " .. track)
	else
		print("Failed to play: " .. track)
	end
end

M.list_playlists = function()
	print(am_run("get name of playlists"))
end

M.play_playlist = function(playlist)
	local cmd = string.format([[
		osascript -e '
			tell application "Music" to play playlist "%s"
		end'
	]], playlist)

	if execute(cmd) then
		print("Successfully started playing playlist: " .. playlist)
	else
		print("Failed to play playlist: " .. playlist)
	end
end

M.play_album = function(album)
	print("Playing album: " .. album)

	local command = string.format([[
        osascript -e '
        tell application "Music"
            set tempPlaylist to make new playlist with properties {name:"%s"}
            set albumTracks to every track of playlist "Library" whose album is "%s"
            repeat with aTrack in albumTracks
                duplicate aTrack to tempPlaylist
            end repeat
            play tempPlaylist
        end tell'
    ]], M.temp_playlist_name, album)

	if execute(command) then
		print("Successfully started playing album: " .. album)
	else
		print("Failed to play album: " .. album)
	end
end

M.next_track = function()
	am_app_run("play next track")
	print("Apple Music: Next Track")
end

M.previous_track = function()
	am_run("previous track")
	print("Apple Music: Previous Track")
end

M.toggle_play = function()
	am_run("to playpause")
	print("Apple Music: Toggled Play/Pause")
end

M.resume = function()
	am_run("play")
	print("Apple Music: Resumed")
end

M.pause = function()
	am_run("pause")
	print("Apple Music: Paused")
end

M.enable_shuffle = function()
	local cmd = [[ osascript -e 'tell application "Music" to set shuffle enabled to true']]

	local handle = io.popen(cmd)
	local result = handle:read("*a")
	handle:close()

	if result then
		print("Apple Music: Shuffle enabled")
	else
		print("Apple Music: Failed to enable shuffle")
	end
end

M.disable_shuffle = function()
	local cmd = [[ osascript -e 'tell application "Music" to set shuffle enabled to false']]

	local handle = io.popen(cmd)
	local result = handle:read("*a")
	handle:close()

	if result then
		print("Apple Music: Shuffle disabled")
	else
		print("Apple Music: Failed to disable shuffle")
	end
end

M.shuffle_is_enabled = function()
	local cmd = [[osascript -e 'tell application "Music" to get shuffle enabled']]
	local handle = io.popen(cmd)
	local result = handle:read("*a")
	handle:close()
	local is_enabled = result:match("true") and true or false
	if is_enabled then
		print("Apple Music: Shuffle is enabled")
	else
		print("Apple Music: Shuffle is disabled")
	end
end

M.cleanup = function()
	for i = 1, 1000 do
		am_run("delete playlist \"" .. M.temp_playlist_name .. "\"")
	end
	print("Apple Music: Cleaned up")
end

M.cleanup_all = function()
	local command = string.format([[
        osascript -e '
        tell application "Music"
            set tempPlaylists to every playlist whose name starts with "%s"
            repeat with aPlaylist in tempPlaylists
                delete aPlaylist
            end repeat
            return (count of tempPlaylists)
        end tell'
    ]], M.temp_playlist_name)

	local handle = io.popen(command)
	local result = handle:read("*a")
	handle:close()

	local count = tonumber(result) or 0

	if count > 0 then
		print(string.format("Removed %d temporary playlist(s)", count))
	else
		print("No temporary playlists found to remove")
	end
end


-- Function to get all playlists from Apple Music
M.get_playlists = function()
	local command = [[osascript -e 'tell application "Music" to get name of playlists']]

	local handle = io.popen(command)
	local result = handle:read("*a")
	handle:close()

	-- Split the result into a table of playlist names
	local playlists = {}
	for playlist in result:gmatch("([^,]+)") do
		playlist = playlist:match("^%s*(.-)%s*$")
		table.insert(playlists, playlist)
	end

	return playlists
end

-- Function to open Telescope picker for playlists
M.select_playlist = function()
	local playlists = M.get_playlists()

	pickers.new({}, {
		prompt_title = "Select a playlist to play",
		finder = finders.new_table {
			results = playlists
		},
		sorter = conf.generic_sorter({}),
		attach_mappings = function(prompt_bufnr, map)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				M.play_playlist(selection[1])
			end)
			return true
		end,
	}):find()
end

return M
