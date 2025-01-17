" https://github.com/lambdalisue/fern.vim/blob/master/doc/fern.txt
" Disable netrw.
let g:fern#renderer = "nerdfont"
augroup my-fern-hijack
  autocmd!
  autocmd BufEnter * ++nested call s:hijack_directory()
augroup END

function! s:hijack_directory() abort
  let path = expand('%:p')
  if !isdirectory(path)
    return
  endif
  bwipeout %
  execute printf('Fern %s', fnameescape(path))
endfunction

" Custom settings and mappings.
let g:fern#disable_default_mappings = 1
let g:fern#default_hidden=1
let g:fern#autoclose=1
let g:fern#hide_cursor=1

noremap <silent> F :let g:fern#autoclose=1 <bar> :Fern %:h -drawer -reveal=%:p<CR>
noremap <silent> <c-b> :let g:fern#autoclose=0 <bar> :Fern . -drawer -reveal=% -toggle<CR><C-w>=

" if &background=='dark'
"   hi FernBranchText  ctermfg=223 ctermbg=232 guifg=#fabd2f guibg=NONE
" else
"   hi FernBranchText  ctermfg=223 ctermbg=232 guifg=#0277BD guibg=NONE
" endif

function! s:closeFern(target) abort
  if a:target == "split"
    execute "normal \<Plug>(fern-action-open:split)"
  elseif a:target== "vsplit"
    execute "normal \<Plug>(fern-action-open:vsplit)"
  else
    execute "normal \<Plug>(fern-action-open)"
  endif
  if g:fern#autoclose ==1
    execute "FernDo close -drawer -stay"
  endif
endfunction

function! s:DownloadFile() abort
    execute "normal \<Plug>(fern-action-yank:path)"
    let l:text=getreg('+')
    echom " . l:text: ".l:text
    execute "AsyncRunSilent cpdragon " . l:text
endfunction

function! FernInit() abort
  nmap <silent> <buffer> <Plug>(fern-my-open-and-close) :<c-u>call <sid>closeFern("") <CR>
  nmap <silent> <buffer> <Plug>(fern-my-open-and-close:split) :<c-u>call <sid>closeFern("split") <CR>
  nmap <silent> <buffer> <Plug>(fern-my-open-and-close:vsplit) :<c-u>call <sid>closeFern("vsplit") <CR>
  nmap <buffer><expr>
        \ <Plug>(fern-my-open-expand-collapse)
        \ fern#smart#leaf(
        \   "\<Plug>(fern-my-open-and-close)",
        \   "\<Plug>(fern-action-expand)",
        \   "\<Plug>(fern-action-collapse)",
        \ )
  nmap <buffer> l <Plug>(fern-my-open-expand-collapse)
  nmap <buffer> h <Plug>(fern-action-collapse)
  nmap <buffer> <CR> <Plug>(fern-my-open-expand-collapse)
  nmap <buffer> <2-LeftMouse> <Plug>(fern-my-open-expand-collapse)
  nmap <buffer> u <Nop>
  nmap <buffer> n <Plug>(fern-action-new-path)
  nnoremap <buffer> <leader>n n
  nmap <buffer> dd <Plug>(fern-action-remove)
  nmap <buffer> yn <Plug>(fern-action-yank:label)
  nmap <buffer> yf <Plug>(fern-action-yank:path)

  nmap <buffer> cm <Plug>(fern-action-clipboard-move)
  nmap <buffer> cp <Plug>(fern-action-clipboard-paste)
  nmap <buffer> cc <Plug>(fern-action-clipboard-copy)
  nmap <buffer> yy <Plug>(fern-action-clipboard-copy)
  nmap <buffer> cx <Plug>(fern-action-mark:clear)
  nmap <buffer> dr :<c-u>call <sid>DownloadFile() <CR>
  nmap <buffer> M <Plug>(fern-action-rename)
  nmap <buffer> cw <Plug>(fern-action-rename:split)
  " nmap <buffer> h <Plug>(fern-action-hidden:toggle)
  nmap <buffer> r <Plug>(fern-action-reload)
  nmap <buffer> t <Plug>(fern-action-mark)j
  nmap <buffer> b <Plug>(fern-my-open-and-close:split)
  nmap <buffer> <c-l> <Plug>(fern-my-open-and-close:vsplit)
  nmap <buffer><nowait> < <Plug>(fern-action-leave)
  nmap <buffer><nowait> > <Plug>(fern-action-enter)
  nmap <buffer><nowait> z <Plug>(fern-action-zoom)
  nmap <buffer> F :q<CR>
  setlocal foldmethod=manual

  if get(g:,'wind_use_icon', 0) == 1
      let g:glyph_palette#defaults#palette['GlyphPaletteDirectory']=['', '' ]
      let g:glyph_palette#defaults#palette['Error']=['']
      call glyph_palette#apply()
  endif
endfunction

augroup FernGroup
  autocmd!
  autocmd FileType fern call FernInit()
augroup END

"=================================="
"          Icon glyph           "
"=================================="

augroup fern-glyph-palette
  autocmd!
  autocmd FileType fern-replacer  setlocal foldmethod=manual | nnoremap <buffer> <c-s> :w<cr>
  autocmd FileType fern  setlocal norelativenumber | setlocal nonumber | setlocal signcolumn=no 
  " set color on icon
  "
augroup END
