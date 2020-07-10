" phab.vim - fugitive.vim extension for GitHub
" Maintainer:   Tim Pope <http://tpo.pe/>

if exists("g:loaded_phab") || v:version < 700 || &cp
  finish
endif
let g:loaded_phab = 1

function! s:Config() abort
  if exists('*FugitiveFind')
    let dir = FugitiveFind('.git/config')[0:-8]
  else
    let dir = get(b:, 'git_dir', '')
    let common_dir = b:git_dir . '/commondir'
    if filereadable(dir . '/commondir')
      let dir .= '/' . readfile(common_dir)[0]
    endif
  endif
  return filereadable(dir . '/config') ? readfile(dir . '/config') : []
endfunction

augroup phab
  autocmd!
  autocmd BufNewFile,BufRead *.commit-message
        \ if &ft ==# '' || &ft ==# 'conf' |
        \   set ft=gitcommit |
        \ endif
augroup END

if !exists('g:fugitive_browse_handlers')
  let g:fugitive_browse_handlers = []
endif

if index(g:fugitive_browse_handlers, function('phab#FugitiveUrl')) < 0
  call insert(g:fugitive_browse_handlers, function('phab#FugitiveUrl'))
endif
