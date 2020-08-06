" Location: autoload/phab.vim
" Author: Tim Pope <http://tpo.pe/>

if exists('g:autoloaded_phab')
  finish
endif
let g:autoloaded_phab = 1

" Section: Utility

function! s:throw(string) abort
  let v:errmsg = 'phab: '.a:string
  throw v:errmsg
endfunction

function! s:shellesc(arg) abort
  if a:arg =~# '^[A-Za-z0-9_/.-]\+$'
    return a:arg
  elseif &shell =~# 'cmd' && a:arg !~# '"'
    return '"'.a:arg.'"'
  else
    return shellescape(a:arg)
  endif
endfunction

function! phab#HomepageForUrl(url) abort
  let domain_pattern = 'phab\.com'
  let domains = get(g:, 'phab_urls', get(g:, 'fugitive_phab_domains', []))
  call map(copy(domains), 'substitute(v:val, "/$", "", "")')
  for domain in domains
    let domain_pattern .= '\|' . escape(split(domain, '://')[-1], '.')
  endfor
  let base = matchstr(a:url, '^\%(https\=://\%([^@/:]*@\)\=\|git://\|git@\|ssh://git@\)\=\zs\('.domain_pattern.'\)[/:].\{-\}\ze\%(\.git\)\=/\=$')
  " FIXME: strip port and assume default
  let base = substitute(base, ":[^/]*", "", "")
  if index(domains, 'http://' . matchstr(base, '^[^:/]*')) >= 0
    return 'http://' . tr(base, ':', '/')
  elseif !empty(base)
    return 'https://' . tr(base, ':', '/')
  else
    return ''
  endif
endfunction

function! phab#homepage_for_url(url) abort
  return phab#HomepageForUrl(a:url)
endfunction

function! s:repo_homepage() abort
  if exists('b:phab_homepage')
    return b:phab_homepage
  endif
  if exists('*FugitiveRemoteUrl')
    let remote = FugitiveRemoteUrl()
  else
    let remote = fugitive#repo().config('remote.origin.url')
  endif
  let homepage = phab#HomepageForUrl(remote)
  if !empty(homepage)
    let b:phab_homepage = homepage
    return b:phab_homepage
  endif
  call s:throw((len(remote) ? remote : 'origin') . ' is not a phab repository')
endfunction

" Section: Fugitive :Gbrowse support

function! phab#FugitiveUrl(...) abort
  if a:0 == 1 || type(a:1) == type({})
    let opts = a:1
    let root = phab#HomepageForUrl(get(opts, 'remote', ''))
  else
    return ''
  endif
  if empty(root)
    return ''
  endif
  let path = substitute(opts.path, '^/', '', '')
  if path =~# '^\.git/refs/heads/'
    return root . '/commits/' . path[16:-1]
  elseif path =~# '^\.git/refs/tags/'
    return root . '/releases/tag/' . path[15:-1]
  elseif path =~# '^\.git/refs/remotes/[^/]\+/.'
    return root . '/commits/' . matchstr(path,'remotes/[^/]\+/\zs.*')
  elseif path =~# '^\.git/\%(config$\|hooks\>\)'
    return root . '/admin'
  elseif path =~# '^\.git\>'
    return root
  endif
  if opts.commit =~# '^\d\=$'
    return ''
  else
    let commit = opts.commit
  endif
  if get(opts, 'type', '') ==# 'tree' || opts.path =~# '/$'
    let url = substitute(root . '/tree/' . commit . '/' . path, '/$', '', 'g')
  elseif get(opts, 'type', '') ==# 'blob' || opts.path =~# '[^/]$'
    let escaped_commit = substitute(commit, '#', '%23', 'g')
    let url = root . '/browse/' . escaped_commit . '/' . path
    if get(opts, 'line2') && opts.line1 == opts.line2
      let url .= '$' . opts.line1
    elseif get(opts, 'line2')
      let url .= '$' . opts.line1 . '-' . opts.line2
    endif
  else
    let url = root . '/browse/' . commit . '/'
  endif
  return url
endfunction

function! phab#fugitive_url(...) abort
  return call('phab#FugitiveUrl', a:000)
endfunction

" Section: End
