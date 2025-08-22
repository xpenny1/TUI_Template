#!/usr/bin/env bash


main() {
    screenSize
    coproc READCURSOR { readCursor; }
    alternateScreenBuffer -e
    selected=1
    while ! selected=$(choose $selected "$@"); do screenSize; done
    alternateScreenBuffer -q
    echo $selected
}

err() {
    echo $1 >&2
    exit 1
}

unhandled() {
    err "Das Argument $1 wird in $2 nich korrekt behandelt!"
}

readCursor() {
    IFS='[;' read -rs -d 'R'  -p $'\e[6n' _ cursor_y cursor_x _  
}

screenSize() {
    readCursor
    old_x=$cursor_x
    old_y=$cursor_y
    printf "\e[999;999;H"
    readCursor
#    old_screen_x=$screen_x
#    old_screen_y=$screen_y
    screen_x=$cursor_x
    screen_y=$cursor_y
#    [[ $old_screen_x != $screen_x || $old_screen_y != $screen_y ]] && printf "\e[J" >&2
    printf "\e[%s;%s;H" "$old_y" "$old_x"
    
}

alternateScreenBuffer() {
    OPTIND=1
    while getopts "esdq" arg; do
        case $arg in
            "e"|"s") printf "\e[?1049h"   ;;
            "d"|"q") printf "\e[?1049l"   ;;
            *) unhandled "$arg" readCursor;;
        esac
    done
}
readKey() {
    local key
    IFS= read -rs -d $'\0' -t 1 -n 1 key
    case $key in
        [a-z,A-Z,0-9]) echo Alpha $key   ;;
                $'\e') readEscape;;
                $'\12') echo Enter;;
                    *) echo Unknown;;
    esac    
}
readEscape() {
    local key
    IFS= read -rs -t 0.1 -n 1 key
    [[ $key != "[" ]] && { echo Unknown; return 1; }
    read -rsn 1 key
    case $key in
            A) echo Escape Up                    ;;
            B) echo Escape Down                  ;;
            C) echo Escape Right                 ;;
            D) echo Escape Left                  ;;
            *) echo Unknown $key; return 1;;
    esac    
}


choose() {
    local selected=$1
    shift
    local current=1
    for arg in "$@"; do
        printf '\e[%s;%sH' "$current" "$((screen_x / 2))" >&2
        printf "\e[2K" >&2
        [[ "$current" == "$selected" ]] && echo -e "\e[38;5;212m""$arg\e[0m" >&2 \
                                        || echo "$arg" >&2
        current=$((current+1))
    done
    key=$(readKey)
    case $key in
        "Escape Down" | "Alpha j")  selected=$(( $# < selected+1 ? $#  : selected+1 ));;
        "Escape Up"   | "Alpha k")    selected=$(( 1  > selected-1 ? 1   : selected-1 ));;
        "Escape Right"| "Alpha l" | "Enter") eval "echo \$$selected"; return 0;;
                     *) ;;
    esac
    echo $selected
    return 1
}

main "$@"
