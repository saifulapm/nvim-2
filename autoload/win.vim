"" Name: autoload/win.vim
"" Author: Maxim Kim <habamax@gmail.com>
"" Desc: Windows manipulation functions.


"" Delete all(saved) but visible buffers
func! win#delete_buffers()
    let l:buffers = filter(getbufinfo(), {_, v -> v.hidden})
    if !empty(l:buffers)
        execute 'bwipeout' join(map(l:buffers, {_, v -> v.bufnr}))
    endif
endfunc


"" Scroll other(previous) window
func! win#scroll_other(dir) abort
    if winnr('$') < 2
        return
    endif
    wincmd p
    let cmd = "normal ".winheight(0)
    if a:dir
        let cmd .= "\<c-e>"
    else
        let cmd .= "\<c-y>"
    endif
    exe cmd
    wincmd p
endfunc


"" Autosize windows.
"" There is lens.vim plugin but essentially this simplified version could be used
"" instead. Original lens.vim laaaags if switched to a huge file, it
"" calculates target width consuming whole file into memory....
""
"" Add following lines somewhere in your vimrc:
"" augroup autosize_windows | au!
""     au BufWinEnter,WinEnter * silent! call win#lens()
"" augroup end
let g:lens_block_next = 0
func! win#lens() abort
    if s:is_lens_disabled()
        " when come back from floating window we don't update it
        " it happen with completin nvim
        let g:lens_block_next = 1
        return
    endif
    if g:lens_block_next == 1
        let g:lens_block_next = 0
        return
    end

    let default_width = s:win_default_width(80)

    let width = max([
                \ get(g:, "lens_pref_width", default_width),
                \ winwidth(0)
                \ ])
    let height = max([
                \ get(g:, "lens_pref_height", 20),
                \ winheight(0)
                \ ])

    execute printf('vertical resize %s', width)
    execute printf('resize %s', height)
    call s:fix_w_h(1)
    wincmd =
    call s:fix_w_h(0)
    normal! ze
endfunction


"" Return width of a signcolumn
func! s:signcolumn_width() abort
    let sc = matchlist(&signcolumn, '\(yes\|auto\)\%(:\(\d\)\)\?')

    if empty(sc)
        return 0
    endif

    if sc[1] == "yes"
        return (sc[2] == '' ? 2 : sc[2])
    endif

    if sc[1] == "auto" && !empty(sign_getplaced("%")[0].signs)
        return (sc[2] == '' ? 2 : sc[2])
    endif
endfunc


"" Return default window width (including linenr and signcolumn)
func! s:win_default_width(width) abort
    let width = a:width
    if &number || &relativenumber
        let width += max([strlen(line('$')), &numberwidth])
    endif
    if &foldcolumn
        let width += max([1, &foldcolumn])
    endif
    let width += s:signcolumn_width()
    return width
endfunc


func! s:is_lens_disabled() abort
    " do not resize floating windows
    if exists('*nvim_win_get_config')
        if nvim_win_get_config(0)['relative'] != ''
            return v:true
        endif
    endif

    " do not resize windows with filetype
    if index(get(g:, "lens_disabled_filetypes", []), &filetype) != -1
        return v:true
    endif

    if get(w:, 'resize_active', 0) == 1
        return v:true
    endif

    return v:false
endfunc


func! s:fix_w_h(val)
    call setwinvar(winnr(), "&winfixwidth", a:val)
    call setwinvar(winnr(), "&winfixheight", a:val)
    for w in range(1, winnr('$'))
        let ft = getbufvar(winbufnr(w), "&filetype", "")
        if index(get(g:, "lens_disabled_filetypes", []), ft) != -1
            call setwinvar(w, "&winfixwidth", a:val)
            call setwinvar(w, "&winfixheight", a:val)
        endif
    endfor
endfunc


"" 5 layouts
"" layout 1: even horizontal
"" layout 2: even vertical
"" layout 3: main horizontal
"" layout 4: main vertical
"" layout 5: tiled
func! win#layout_toggle() abort
    if winnr('$') == 1
        return "Single window"
    endif

    if winnr('$') == 2
        let win_layouts =
                    \ {1: {"f": "win#layout_horizontal", "next": 2}
                    \ ,2: {"f": "win#layout_vertical", "next": 1}
                    \ }
    elseif winnr('$') == 3
        let win_layouts =
                    \ {1: {"f": "win#layout_horizontal", "next": 2}
                    \ ,2: {"f": "win#layout_vertical", "next": 3}
                    \ ,3: {"f": "win#layout_main_horizontal", "next": 4}
                    \ ,4: {"f": "win#layout_main_vertical", "next": 1}
                    \ }
    else
        let win_layouts =
                    \ {1: {"f": "win#layout_horizontal", "next": 2}
                    \ ,2: {"f": "win#layout_vertical", "next": 3}
                    \ ,3: {"f": "win#layout_main_horizontal", "next": 4}
                    \ ,4: {"f": "win#layout_main_vertical", "next": 5}
                    \ ,5: {"f": "win#layout_tile", "next": 1}
                    \ }
    endif

    let layout_echo = ""
    let layout = min([get(t:, "window_layout", len(win_layouts)), len(win_layouts)])


    let layout_echo = function(win_layouts[layout].f)()
    let t:window_layout = win_layouts[layout].next

    call win#lens()

    return layout_echo
endfunc


func! win#layout_horizontal() abort
    let winid = win_getid()
    windo wincmd L
    call win_gotoid(winid)
    wincmd H
    return "Even horizontal layout"
endfunc


func! win#layout_vertical() abort
    let winid = win_getid()
    windo wincmd K
    call win_gotoid(winid)
    wincmd K
    return "Even vertical layout"
endfunc


func! win#layout_main_horizontal() abort
    let winid = win_getid()
    windo wincmd L
    call win_gotoid(winid)
    wincmd K
    return "Main horizontal layout"
endfunc


func! win#layout_main_vertical() abort
    let winid = win_getid()
    windo wincmd K
    call win_gotoid(winid)
    wincmd H
    return "Main vertical layout"
endfunc


func! win#layout_tile() abort
    let windows = []
    let buffers = []

    for w in range(1, winnr('$'))
        if w != winnr()
            call add(buffers, winbufnr(w))
        endif
    endfor

    silent only
    call add(windows, win_getid())

    let half = len(buffers)/2

    let splitbelow = &splitbelow
    let splitright = &splitright
    try
        setl splitbelow
        setl splitright

        for bnr in range(half)
            split
            call add(windows, win_getid())
            silent exe printf("buffer %s", buffers[bnr])
        endfor

        let win_idx = 0
        for bnr in range(half, len(buffers) - 1)
            silent call win_gotoid(windows[win_idx])
            vsplit
            silent exe printf("buffer %s", buffers[bnr])

            let win_idx += 1
        endfor

        silent call win_gotoid(windows[0])
    finally
        let &splitbelow = splitbelow
        let &splitright = splitright
    endtry

    return "Tiled layout"
endfunc



""" Zoom window: save and restore window layout
"" nnoremap <silent> <C-w>o :call win#zoom_toggle()<CR>
"" <C-w>o zoom window (there should be only 1 window)
"" <C-w>o restores previous windows
func! win#zoom_toggle() abort
    if winnr('$') == 1 && get(t:, "zoomed", v:false)
        call s:layout_restore()
        let t:zoomed = v:false
    else
        let t:zoomed = v:true
        call s:layout_save()
        silent wincmd o
    endif
endfunc


func! s:layout_save(...) abort
    let t:zoom_winrestcmd = winrestcmd()
    let t:zoom_layout = winlayout()
    let t:zoom_cursor = [winnr(), getcurpos()]
    call s:add_buf_to_layout(t:zoom_layout)
endfunc


func! s:layout_restore() abort
    if empty(get(t:, "zoom_layout", []))
        return
    endif

    " Close other windows
    silent wincmd o

    " recursively restore buffers
    call s:apply_layout(get(t:, "zoom_layout"))

    " resize
    exe t:zoom_winrestcmd

    " goto saved window
    exe printf("%dwincmd w", t:zoom_cursor[0])

    " set cursor
    call setpos('.', t:zoom_cursor[1])
endfunc


" add bufnr to leaf
func! s:add_buf_to_layout(layout) abort
    if a:layout[0] ==# 'leaf'
        " replace win_id with buffer number
        let a:layout[1] = winbufnr(a:layout[1])
    else
        for child_layout in a:layout[1]
            call s:add_buf_to_layout(child_layout)
        endfor
    endif
endfunc


func! s:apply_layout(layout) abort
    if a:layout[0] ==# 'leaf'
        " load buffer for leaf
        if bufexists(a:layout[1])
            exe printf('b %d', a:layout[1])
        endif
    else
        " split cols or rows, split n-1 times
        let split_method = a:layout[0] ==# 'col' ? 'rightbelow split' : 'rightbelow vsplit'
        let wins = [win_getid()]
        for child_layout in a:layout[1][1:]
            exe split_method
            let wins += [win_getid()]
        endfor

        " recursive into child windows
        for index in range(len(wins) )
            call win_gotoid(wins[index])
            call s:apply_layout(a:layout[1][index])
        endfor
    endif
endfunc
