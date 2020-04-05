" =============================================================
" Name:         vim-blameline
" Maintainer:   Danish Prakash
" HomePage:     https://github.com/danishprakash/vim-blameline
" License:      GNU GPL
" =============================================================


command! -nargs=0 GetBlame call blameline#SetBlame()

autocmd CursorMoved * call blameline#SetBlame()


" augroup blame
"     autocmd!
"     autocmd CursorHold * :Blameline(0)
"     autocmd CursorMoved * :Blameline(1)
"     autocmd TextChanged * :BlamelineUpdate
"     autocmd BufWinEnter * :BlamelineUpdate
" augroup END
