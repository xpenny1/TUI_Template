#!/usr/bin/env bash


main() {
    alternateScreenBuffer -e
    choosen=$(choose "$@")
    alternateScreenBuffer -q
    echo $choosen
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
        [a-z,A-Z,0-9]) echo alpha $key   ;;
                $'\e') readEscape  ;;
                    *) echo Unknown;;
    esac    
}
readEscape() {
    local key
    read -rsn 1 key
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
    local selected=1
    while true; do
        local current=1
        for arg in "$@"; do
            printf '\e[%s;H' "$current" >&2
            [[ "$current" == "$selected" ]] && echo -e "\e[38;5;212m""$arg\e[0m" >&2 \
                                             || echo "$arg" >&2
            current=$((current+1))
        done
        key=$(readKey)
        case $key in
               "Escape Up")    selected=$(( 1  > selected-1 ? 1   : selected-1 ));;
             "Escape Down")  selected=$(( $# < selected+1 ? $#  : selected+1 ));;
            "Escape Right") break;;
                         *) ;;
        esac
    done
    eval "echo \$$selected"
}

main "$@"
