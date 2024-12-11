# Neovim Apple Music Plugin

This Neovim plugin allows you to control Apple Music directly from within Neovim using Lua and Telescope. You can play tracks, playlists, and albums, and control playback without leaving your favorite text editor.

![Demo of Selecting Album via Telescope](demos/select_album.gif)

## Features

- Play specific tracks, playlists, or albums.
- Control playback (play, pause, next track, previous track, toggle play/pause).
- Enable or disable shuffle.
- View and select entries using Telescope picker.

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

Here is how I have this plugin setup, minus the dev stuff.

```lua
{
    'p5quared/apple-music.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    config = true,
    keys = {
        { "<leader>amp", function() require("apple-music").toggle_play() end,               desc = "Toggle [P]layback" },
        { "<leader>ams", function() require("apple-music").toggle_shuffle() end,            desc = "Toggle [S]huffle" },
        { "<leader>fp",  function() require("apple-music").select_playlist_telescope() end, desc = "[F]ind [P]laylists" },
        { "<leader>fa",  function() require("apple-music").select_album_telescope() end,    desc = "[F]ind [A]lbum" },
        { "<leader>fs",  function() require("apple-music").select_track_telescope() end,    desc = "[F]ind [S]ong" },
        { "<leader>amx", function() require("apple-music").cleanup_all() end,               desc = "Cleanup Temp Playlists" },
    },
}
```

I think this is a good overview of the main functionality as well.
Toggling playback is arguably just as easy to do with general keyboard shortcuts
(nowadays you often have media keys). I think the ability to browse
and play via telescope is the the most useful feature of this plugin.

Note that you have to manually cleanup the temporary playlists created by this plugin.
In the future I may try to come up with an autocmd solution.

## Configuration

You can customize the plugin by passing options to the `setup` function:

```lua
require('apple-music').setup({
  temp_playlist_name = "nvim_apple_music_temp"  -- Custom temporary playlist name
})
```

## Usage

### Commands

See [doc/apple-music.txt](doc/apple-music.txt) for an overview of commands.

## Example

To play a specific track, you can use the following command in Neovim:

```vim
:lua require('apple-music').play_track("Bohemian Rhapsody")
```

To open the Telescope picker and select a playlist to play:

```vim
:lua require('apple-music').select_playlist_telescope()
```

### Example (lualine)

This example demonstrates how to integrate with lualine.
Other statusline plugins can be used as well, and the process should be similar.
Refer to the documentation of your statusline plugin for more information.

```lua
require('lualine').setup {
  sections = {
    lualine_x = {
      require("apple-music")._current_track,
    }
  }
}
```

## License

This plugin is released under the MIT License. See [LICENSE](./LICENSE) for more information.

## Contributions

Contributions are welcome! Please feel free to open issues or submit pull requests on GitHub.
Before opening pull requests, please run `stylua` locally.

## Acknowledgements

- [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [mcthomas/Apple-Music-CLI-Player](https://github.com/mcthomas/Apple-Music-CLI-Player)
  - Much of the Apple Script was taken/heavily inspired from this repo.
    I probably could have pieced together a lot of the basic stuff, but probably
    not the workaround for playing albums with temporary playlists...
- [Temporary Playlist Workaround](https://discussions.apple.com/thread/1053355?sortBy=best)
  - Well that temp playlist workaround from mcthomas was actually from here.
