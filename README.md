<h1 align="center">nvim-blameline</h1>
<p align="center">Experimental implementation of GitLens's line blame for Nvim.</p>
<p align="center">
<img src="https://i.imgur.com/r8Jz8Rd.gif" height="600">
</p>

## What?
Blameline allows you to preview the blame details for the current line. It does so using the `git blame` command. It is inspired by the current line blame functionality offered by GitLens for VSCode. It uses the virtualtext API from NeoVim to display the blame metadata in the buffer.

## Commands
```text
:BlamelineEnable
    BlamelineEnable shows the blame metadata on the current lie and
    creates autocmds to alter the behaviour of the plugin.

:BlamelineDisable
    BlamelineDisable clears the blame metadata from the current line and
    also clears the autocommands setup by BlamelineEnable.
```

## Options
```vim
let g:blameline_delay_time
    Delay (in ms) before the commit metadata is shown (default: 1000)

let g:blameline_filetype_blacklist
    Filetypes on which blameline should not act.
    Defaults to the following:
        let g:blameline_filetype_blacklist = [
        \   'help',
        \   'nerdtree',
        \   'quickfix',
        \   'tags',
        \]
```

## Installation
```vim
Plug 'danishprakash/nvim-blameline'
```

## Contributing
Do you want to make this better? Open an issue and/or a PR on Github. Thanks!

## License
GNU GPL v3

Copyright (c) 2020 [Danish Prakash](https://github.com/danishprakash)
