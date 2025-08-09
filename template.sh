#!/usr/bin/env bash

main() {
    alternateScreenBuffer -e
    echo reading Key
    c="$(readKey)"
    echo reading "done"
    alternateScreenBuffer -q
    echo $c
}

err() {
    echo $1 >&2
    exit 1
}

unhandled() {
    err "Das Argument $1 wird in $2 nich korrekt behandelt!"
}

readCursor() {
    local varName=cursor
    OPTIND=1
    while getopts "c:h" arg; do
        case $arg in
            "c") local varName=$OPTARG;;
            "h") err "readCursor [-c <varName>]";;
            "?") err "readCursor [-c <varName>]";;
            *) unhandled "$arg" readCursor;;
        esac
    done
    printf "\e[6n"
    read -srn 2
    IFS=';' read -sr -d R -a $varName
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
    read -rsn 1 key
    case $key in
        [a-z,A-Z,0-9]) echo $key   ;;
                $'\e') readEscape  ;;
                    *) echo Unknown;;
    esac    
}
readEscape() {
    echo Escape
    local key
    read -rsn 1 key
    [[ $key != "[" ]] && { echo Unknown; return 1; }
    read -rsn 1 key
    case $key in
            A) echo Up                    ;;
            B) echo Down                  ;;
            C) echo Right                 ;;
            D) echo Left                  ;;
            *) echo Unknown $key; return 1;;
    esac    
}


choose() {
    local s=1
    while true; do
        local i=1
        for arg in "$@"; do
            printf '\e[%s;H' "$i" >&2
            [[ "$i" == "$s" ]] && echo -e "\e[38;5;212m""$arg\e[0m" >&2 \
                               || echo "$arg" >&2
            i=$((i+1))
        done
        read -t 0.1
        key=$(readArrow)
        case $key in
            Up)    s=$(( 1  > s-1 ? 1   : s-1 ));;
            Down)  s=$(( $# < s+1 ? $#  : s+1 ));;
            Right) break;;
        esac
    done
    eval "echo \$$s"
}

main
