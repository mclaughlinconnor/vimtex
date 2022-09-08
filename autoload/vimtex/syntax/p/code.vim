" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#code#load(cfg) abort " {{{1
  " Parse minted macros in the current project
  call s:parse_minted_constructs()

  " Match minted environment boundaries
  syntax match texMintedEnvBgn contained '\\begin{code}'
        \ nextgroup=texMintedEnvOpt,texMintedEnvArg skipwhite skipnl
        \ contains=texCmdEnv
  "
  " Next add nested syntax support for desired languages
  for [l:nested, l:config] in items(b:vimtex.syntax.code)
    let l:cluster = vimtex#syntax#nested#include(l:nested)

    let l:name = toupper(l:nested[0]) . l:nested[1:]
    let l:grp_env = 'texMintedZone' . l:name
    let l:grp_inline = 'texMintedZoneInline' . l:name
    let l:grp_inline_matcher = 'texMintedArg' . l:name

    let l:options = 'keepend'
    let l:contains = 'contains=texCmdEnv,texMintedEnvBgn'
    let l:contains_inline = ''

    if !empty(l:cluster)
      let l:contains .= ',@' . l:cluster
      let l:contains_inline = '@' . l:cluster
    else
      execute 'highlight def link' l:grp_env 'texMintedZone'
      execute 'highlight def link' l:grp_inline 'texMintedZoneInline'
    endif

    " Match normal minted environments
    execute 'syntax region' l:grp_env
          \ 'start="\\begin{code}\%(\_s*\[\_[^\]]\{-}\]\)\?\_s*{' . l:nested . '}"'
          \ 'end="\\end{code}"'
          \ l:options
          \ l:contains
  endfor
endfunction

function s:parse_minted_constructs() abort
  let l:db = deepcopy(s:db)
  let b:vimtex.syntax.code = l:db.data

  let l:in_multi = 0
  for l:line in vimtex#parser#tex(b:vimtex.tex, {'detailed': 0})
    " Multiline minted environments
    if l:in_multi
      let l:lang = matchstr(l:line, '\]\s*{\zs\w\+\ze}')
      if !empty(l:lang)
        call l:db.register(l:lang)
        let l:in_multi = 0
      endif
      continue
    endif
    if l:line =~# '\\begin{code}\s*\[[^\]]*$'
      let l:in_multi = 1
      continue
    endif

    " Single line minted environments
    let l:lang = matchstr(l:line, '\\begin{code}\%(\s*\[[^\]]*\]\)\?\s*{\zs\w\+\ze}')
    if !empty(l:lang)
      call l:db.register(l:lang)
      continue
    endif
  endfor
endfunction

let s:db = {
\ 'data' : {},
\}

function s:db.register(lang) abort dict
  " Avoid dashes in langnames
  let l:lang = substitute(a:lang, '-', '', 'g')

  if !has_key(self.data, l:lang)
    let self.data[l:lang] = {
          \ 'environments' : [],
          \ 'commands' : [],
          \}
  endif

  let self.cur = self.data[l:lang]
endfunction

" }}}1
