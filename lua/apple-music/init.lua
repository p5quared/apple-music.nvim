---@mod apple-music.intro INTRODUCTION
---@brief [[
---
--- This is a simple plugin to control Apple Music using Neovim.
--- It uses AppleScript to control the Music app on macOS.
---
--- For example,
---
--->
---   require('apple-music').play_track("Sir Duke")
---<
---@brief ]]
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

local grab_os_version = function()
	local cmd = [[ osascript -e 'set osver to system version of (system info)' ]]
	local _, result = execute(cmd)
	return tonumber(result)
end

---@mod apple-music.nvim PLUGIN OVERVIEW
local M = {}

---NOTE: Requires the song to be an exact title (not fuzzy)

---Setup the plugin
---@param opts table|nil: Optional configuration for the plugin
--- * {temp_playlist_name: string} - The name of the temporary playlist to use
--- 								(see `apple-music.caveats` for details on temporary playlists)
M.setup = function(opts)
	M.temp_playlist_name = opts.temp_playlist_name or "apple-music.nvim"
end

---Play a track by title
---@param track string: The title of the track to play
---@usage require('apple-music').play_track("Sir Duke")
M.play_track = function(track)
	print("Playing " .. track)
	local command = string.format([[
        osascript -e '
        tell application "Music"
            play track "%s"
        end tell'
    ]], track)

	local result = execute(command)
end

---Play a playlist by name
---@param playlist string: The name of the playlist to play
---@usage require('apple-music').play_playlist("Slow Dance")
M.play_playlist = function(playlist)
	local cmd = string.format([[
		osascript -e '
			tell application "Music" to play playlist "%s"
		end'
	]], playlist)

	if execute(cmd) then
		print("Playing playlist: " .. playlist)
	else
		print("Failed to play playlist: " .. playlist)
	end
end

---Play an album by name
---NOTE: This will create a temporary playlist with the tracks from the album. See `apple-music.caveats` for details.
---@param album string: The name of the album to play
---@usage require('apple-music').play_album("Nashville Skyline")
M.play_album = function(album)
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
		print("Playing album: " .. album)
	else
		print("Failed to play album: " .. album)
	end
end

---Play the next track
---@usage require('apple-music').next_track()
M.next_track = function()
	am_app_run("play next track")
	print("Apple Music: Next Track")
end

---Play the previous track
---@usage require('apple-music').previous_track()
M.previous_track = function()
	am_run("previous track")
	print("Apple Music: Previous Track")
end

---Toggle playback (play/pause)
---@usage require('apple-music').toggle_play()
M.toggle_play = function()
	am_run("playpause")
	print("Apple Music: Toggled Playback")
end

---Resume playback
---@usage require('apple-music').resume()
M.resume = function()
	am_run("play")
	print("Apple Music: Resumed")
end

---Puase Playback
---@usage require('apple-music').pause()
M.pause = function()
	am_run("pause")
	print("Apple Music: Paused")
end

---Enable shuffle
---@usage require('apple-music').enable_shuffle()
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

---Disable shuffle
---@usage require('apple-music').disable_shuffle()
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

---Change the favorited state of the current music.
---It also handles Mac OS versions below 14 (Sonoma) where it used to be called "loved".
---@param state boolean: The state of favorited to be set for current track.
---@usage require('apple-music').set_current_track_favorited(true)
---@usage require('apple-music').set_current_track_favorited(false)
M.set_current_track_favorited = function(state)
  local cmd_property = "favorited"
  if grab_os_version() < 14 then
    cmd_property = "loved"
  end
	local command = string.format([[
    osascript -e 'tell application "Music" to set %s of current track to "%s"'
  ]], cmd_property, state)
	execute(command)
end

---Toggle shuffle
---@usage require('apple-music').toggle_shuffle()
M.toggle_shuffle = function()
	if M.shuffle_is_enabled() then
		M.disable_shuffle()
		print("Apple Music: Shuffle disabled")
	else
		M.enable_shuffle()
		print("Apple Music: Shuffle enabled")
	end
end

---Determine if shuffle is enabled
---@usage require('apple-music').shuffle_is_enabled()
M.shuffle_is_enabled = function()
	local cmd = [[osascript -e 'tell application "Music" to get shuffle enabled']]
	local handle = io.popen(cmd)
	local result = handle:read("*a")
	handle:close()
	local is_enabled = result:match("true") and true or false
	return is_enabled
end

M._cleanup = function()
	local cmd = string.format([[
		osascript -e '
		tell application "Music"
			if (exists playlist "%s") then
				delete playlist "%s"
			end if
		end tell'
		]], M.temp_playlist_name, M.temp_playlist_name)

	local handle = io.popen(cmd)
	local result = handle:read("*a")
	handle:close()
end

---Delete temporary playlist. See `apple-music.caveats` for details.
---You may have to call this multiple times to remove all temporary playlists.
---@usage require('apple-music').cleanup()
M.cleanup = function()
	M._cleanup()
	print("Apple Music: Cleaned up")
end

---Cleanup all temporary playlists, as long as you have less than 10...
---You may still have to call this multiple times.
---There may be weird text written to your screen, but restarting neovim will fix this.
---@usage require('apple-music').cleanup_all()
M.cleanup_all = function()
	for i = 1, 10 do
		M._cleanup()
	end
	print("Apple Music: Cleaned up all")
end

---Get a list of playlists from your Apple Music library
---@usage require('apple-music').get_playlists()
M.get_playlists = function()
	local command = [[osascript -e 'tell application "Music" to get name of playlists' -s s]]

	local handle = io.popen(command)
	local result = handle:read("*a")
	handle:close()

	-- Convert table string into table
	local result_chunk = "return " .. result
	local playlists = loadstring(result_chunk)()

	return playlists
end

---Select and play a playlist using Telescope
---@usage require('apple-music').select_playlist_telescope()
M.select_playlist_telescope = function()
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

local remove_duplicates = function(t)
	local hash = {}
	local res = {}

	for _, v in ipairs(t) do
		if not hash[v] then
			res[#res + 1] = v
			hash[v] = true
		end
	end

	return res
end

---Get a list of albums from your Apple Music library
---@usage require('apple-music').get_albums()
M.get_albums = function()
	local command = [[osascript  -e 'tell application "Music" to get album of every track' -s s]]
	local handle = io.popen(command)
	local result = handle:read("*a")
	handle:close()

	-- Convert table string into table
	local result_chunk = "return " .. result
	local albums = loadstring(result_chunk)()

	local unique_albums = remove_duplicates(albums)

	return unique_albums
end

---Select and play an album using Telescope
---@usage require('apple-music').select_album_telescope()
M.select_album_telescope = function()
	local albums = M.get_albums()

	pickers.new({}, {
		prompt_title = "Select an album to play",
		finder = finders.new_table {
			results = albums
		},
		sorter = conf.generic_sorter({}),
		attach_mappings = function(prompt_bufnr, map)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				M.play_album(selection[1])
			end)
			return true
		end,
	}):find()
end

---Get the name and artist of the current track (in the following format: <name> - <author>).
---@usage require('apple-music').get_current_track()
M.get_current_track = function()
  local command = [[osascript -e 'tell application "Music" to get {name, artist} of current track' -s s]]
  local _, result = execute(command)
	local result_chunk = "return " .. result
	local current_track = loadstring(result_chunk)()
  return current_track[1] .. " - " .. current_track[2]
end

---Get a list of tracks from your Apple Music library
---@usage require('apple-music').get_tracks()
M.get_tracks = function()
	local command = [[osascript  -e 'tell application "Music" to get name of every track' -s s]]
	local handle = io.popen(command)
	local result = handle:read("*a")
	handle:close()

	-- Convert table string into table
	local result_chunk = "return " .. result
	local tracks = loadstring(result_chunk)()

	return tracks
end

---Select and play a track using Telescope
---@usage require('apple-music').select_track_telescope()
M.select_track_telescope = function()
	local tracks = M.get_tracks()
	pickers.new({}, {
		prompt_title = "Select a track to play",
		finder = finders.new_table {
			results = tracks
		},
		sorter = conf.generic_sorter({}),
		attach_mappings = function(prompt_bufnr, map)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				M.play_track(selection[1])
			end)
			return true
		end,
	}):find()
end

return M
