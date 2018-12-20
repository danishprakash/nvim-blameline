" =============================================================
" Name:         vim-blameline
" Maintainer:   Danish Prakash
" HomePage:     https://github.com/danishprakash/vim-blameline
" License:      GNU GPL
" =============================================================


command! -nargs=1 Blameline call blameline#InitBlameline(<args>)
command! -nargs=0 BlamelineUpdate call blameline#GetBlameOutput()

augroup blame
    autocmd!
    autocmd CursorHold * :Blameline(0)
    autocmd CursorMoved * :Blameline(1)
    autocmd TextChanged * :BlamelineUpdate
    autocmd BufWinEnter * :BlamelineUpdate
augroup END
