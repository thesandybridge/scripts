#!/usr/bin/env bash


spinner() {
    # make sure we use non-unicode character type locale
    # (that way it works for any locale as long as the font supports the characters)
    local LC_CTYPE=C

    local pid=$1 # Process Id of the previous running command
    local sp='-\|/'
    local width=1

    local i=0
    tput civis # cursor invisible
    info "$2"
    while kill -0 $pid 2>/dev/null; do
        local i=$(((i + $width) % ${#sp}))
        printf "${blue}%s${reset}" "[${sp:$i:$width}]"

        echo -en "\033[$1D"
        sleep .1
    done
    tput cnorm
    wait $pid # capture exit code
    return $?
}
