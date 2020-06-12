" TODO: Set cmake build type command
" TODO: check if CMakeLists exist
" TODO: Add support for windows since we use perl
"

" let s:shell_check_exit = '; read -n 1 -s -r -p "Press any key to continue"'
let s:shell_check_exit = '; read -k1 -s; tmux select-pane -l'

if !exists("g:cmake_build_dir")
    let g:cmake_build_dir = "./build"
end

if !exists("g:cmake_build_type")
    let g:cmake_build_type = "Debug"
end

function! cmake#make(cmd)
    let s:command = 'cmake -B '.g:cmake_build_dir
    echom "Cmake Executed: ".s:command
    " echom system(s:command)
    execute 'VtrSendCommandToRunner!'.s:command
    " echo 'cmake --B '.g:cmake_build_dir
endfunction

function! cmake#cbuild(...)
    " We are expecting one argument containing executable name
    " a:0 -> returns no of argument
    " a:1 -> returns the first argument and we expect executable name to execute
    let s:executable = get(a:, 1, cmake#getCurrentExecutable())
    let s:command = 'cmake --build '.g:cmake_build_dir.' --config '.g:cmake_build_type.' --target '.s:executable
    echom "Cmake Executed: ".s:command
    " echom system(s:command)
    execute 'VtrSendCommandToRunner!'.s:command
endfunction

function! cmake#getCurrentExecutable()
    " TODO: Check if the current file based executable is set as executable
    " target inside CMakeLists.txt
    " %:r -> returns file name without extension
    return expand('%:r')
endfunction

function! cmake#getBuildType(ArgLead, CmdLine, CursorPos)
    return ['Debug','Release'] + globpath('*', a:ArgLead, 0, 1)
endfunction

function! cmake#getExecutables(ArgLead, CmdLine, CursorPos)
    " Get the list of executables from cmake
    " Pass it to perl expression which extracts all the names without any extension
    " TODO: Check for *.exe optionally to check the status
    " TODO: Find a way to detect cmake error and present it to use
    let s:list_of_executables =
                \ system('cmake --build '.g:cmake_build_dir.
                \' --target help | perl -ne ''while(/(?<=\ )\w+(?!\.)(?=\n)/g){print "$&\n";}''')
    return split(s:list_of_executables, '\n')
endfunction

function! cmake#runExecutable(...)
    " If a executable name is passed, execute it. Otherwise, execute the current
    " detected executable
    if !exists("g:cmake_exec_name")
        let s:temp = cmake#getCurrentExecutable()
        let s:executable = get(a:, 1, s:temp)
        "let s:command = substitute('sh -c '.g:cmake_build_dir.'/'.s:executable, "^L", "", "")
        let s:command = 'sh -c '.g:cmake_build_dir.'/'.s:executable
    else
        let s:command = 'sh -c '.g:cmake_build_dir.'/'.g:cmake_exec_name
    endif
    echom "Cmake Executed: ".s:command
    " To pass argument to a command, we must use execute
    execute 'VtrOpenRunner'
    execute 'VtrSendCommandToRunner!'.s:command.s:shell_check_exit
    execute 'VtrFocusRunner'
endfunction


" Accepts the build directory as input
command! -complete=dir -nargs=? CMake call cmake#make(<q-args>)

" Accepts the target to build as input optionally. Otherwise uses the filename
" to detect the executable name
command! -complete=customlist,cmake#getExecutables -nargs=? CBuild call cmake#cbuild(<f-args>)

" Accepts the target to run as input optionally. Otherwise uses the filename
" to detect the executable name
command! -complete=customlist,cmake#getExecutables -nargs=? CRun call cmake#runExecutable(<f-args>)
