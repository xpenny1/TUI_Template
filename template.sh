#!/usr/bin/env bash

err() {
    echo $1 >&2
    exit 1
}
unhandled() {
    err "Das Argument $1 wird in $2 nich korrekt behandelt!"
}

readCursor() {
    local varName=cursor
    while getopts "c:h" arg; do
        case $arg in
            "c") local varName=$OPTARG;;
            "h") err "readCursor [-c <varName>]";;
            "?") err "readCursor [-c <varName>]";;
            *) unhandled "$arg" readCursor;;
        esac
    done
    printf "\e[6n"
    read -s -n 2
    IFS=';' read -s -d R -a $varName
}

alternateScreenBuffer() {
    while getopts "esdq" arg; do
        case $arg in
            e|s) printf "\e[?1049h"; return;;
            d|q) printf "\e[?1049l"; return;;
            *) unhandled "$arg" readCursor;;
        esac
    done
}
readArrow() {
    read -rsn 1 key
    case $key in
        A) key=Up;;
        B) key=Down;;
        C) key=Right;;
        D) key=Left;;
        *) readArrow;;
    esac
}
alternateScreenBuffer -e
readArrow
alternateScreenBuffer -d
echo $key
