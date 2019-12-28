" pipe() {{{
function! callbag#pipe(...) abort
    let l:Res = a:1
    let l:i = 1
    while l:i < a:0
        let l:Res = a:000[l:i](l:Res)
        let l:i = l:i + 1
    endwhile
    return l:Res
endfunction
" }}}

" forEach() {{{
function! callbag#forEach(operation) abort
    let l:data = { 'operation': a:operation }
    return function('s:forEachOperation', [l:data])
endfunction

function! s:forEachOperation(data, source) abort
    return a:source(0, function('s:forEachOperationSource', [a:data]))
endfunction

function! s:forEachOperationSource(data, t, ...) abort
    if a:t == 0 | let a:data['talkback'] = a:1 | endif
    if a:t == 1 | call a:data['operation'](a:1) | endif
    if (a:t == 1 || a:t == 0) | call a:data['talkback'](1) | endif
endfunction
" }}}

" interval() {{{
function! callbag#interval(period) abort
    let l:data = { 'period': a:period }
    return function('s:intervalPeriod', [l:data])
endfunction

function! s:intervalPeriod(data, start, sink) abort
    if a:start != 0 | return | endif
    let a:data['i'] = 0
    let a:data['sink'] = a:sink
    let a:data['timer'] = timer_start(a:data['period'], function('s:interval_callback', [a:data]), { 'repeat': -1 })
    call a:sink(0, function('s:interval_sink_callback', [a:data]))
endfunction

function! s:interval_callback(data, ...) abort
    let l:i = a:data['i']
    let a:data['i'] = a:data['i'] + 1
    call a:data['sink'](1, l:i)
endfunction

function! s:interval_sink_callback(data, t) abort
    if a:t == 2 | call timer_stop(a:data['timer']) | endif
endfunction
" }}}

" take() {{{
function! callbag#take(max) abort
    let l:data = { 'max': a:max }
    return function('s:takeMax', [l:data])
endfunction

function! s:takeMax(data, source) abort
    let a:data['source'] = a:source
    return function('s:takeMaxSource', [a:data])
endfunction

function! s:takeMaxSource(data, start, sink) abort
    if a:start != 0 | return | endif
    let a:data['taken'] = 0
    let a:data['end'] = 0
    let a:data['sink'] = a:sink
    let a:data['talkback'] = function('s:takeTalkback', [a:data])
    call a:data['source'](0, function('s:takeSourceCallback', [a:data]))
endfunction

function! s:takeTalkback(data, t, ...) abort
    if a:t == 2
        let a:data['end'] = true
        call a:data['sourceTalkback'](a:t, a:1)
    elseif a:data['taken'] < a:data['max']
        if a:0 > 0
            call a:data['sourceTalkback'](a:t, a:1)
        else
            call a:data['sourceTalkback'](a:t)
        endif
    endif
endfunction

function! s:takeSourceCallback(data, t, ...) abort
    if a:t == 0
        let a:data['sourceTalkback'] = a:1
        call a:data['sink'](0, a:data['talkback'])
    elseif a:t == 1
        if a:data['taken'] < a:data['max']
            let a:data['taken'] = a:data['taken'] + 1
            call a:data['sink'](a:t, a:1)
            if a:data['taken'] == a:data['max'] && !a:data['end']
                let a:data['end'] = 1
                call a:data['sink'](2)
                call a:data['sourceTalkback'](2)
            endif
        endif
    else
        call a:data['sink'](a:t, a:1)
    endif
endfunction
" }}}

let s:i = 0
function! s:next(cb) abort
    echom s:i
    let s:i = s:i + 1
endfunction

function! callbag#demo() abort
    let l:res = callbag#pipe(
        \ callbag#interval(1000),
        \ callbag#take(3),
        \ callbag#forEach(function('s:next')),
        \ )
    return l:res
endfunction
"
" vim:ts=4:sw=4:ai:foldmethod=marker:foldlevel=0:
