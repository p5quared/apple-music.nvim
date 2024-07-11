# Neovim Apple Music Plugin

This Neovim plugin allows you to control Apple Music directly from within Neovim using Lua and Telescope. You can play tracks, playlists, and albums, and control playback without leaving your favorite text editor.

![Demo of Selecting Album via Telescope](demos/select_album.gif)

## Features

- Play specific tracks, playlists, or albums.
- Control playback (play, pause, next track, previous track, toggle play/pause).
- Enable or disable shuffle mode.
- View and select playlists using Telescope picker.
- Clean up temporary playlists created for playing albums.
- Asynchronous execution to keep Neovim responsive.
- Informative notifications for all actions.

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'p5quared/nvim-apple-music',
  dependencies = { 'nvim-lua/plenary.nvim', 'nvim-telescope/telescope.nvim' },
  config = true,
}
```

## Configuration

You can customize the plugin by passing options to the `setup` function:

```lua
require('nvim-apple-music').setup({
  temp_playlist_name = "nvim_apple_music_temp"  -- Custom temporary playlist name
})
```

## Usage

### Commands

See [doc/apple-music.txt](doc/apple-music.txt) for an overview of commands.

## Example

To play a specific track, you can use the following command in Neovim:

```vim
:lua require('nvim-apple-music').play_track("Bohemian Rhapsody")
```

To open the Telescope picker and select a playlist to play:

```vim
:lua require('nvim-apple-music').select_playlist_telescope()
```

## License

This plugin is released under the MIT License. See [LICENSE](./LICENSE) for more information.

## Contributions

Contributions are welcome! Please feel free to open issues or submit pull requests on GitHub.

## Acknowledgements

- [nvim-lua/plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
