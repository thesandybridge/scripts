#!/usr/bin/env bash

# DEFINE VARIABLES
grey="\\e[37m"
blue="\\e[36m"
red="\\e[31m"
yellow="\\e[33m"
green="\\e[32m"
reset="\\e[0m"

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

info() { echo -e "${blue}[+] $*${reset}"; }
warn() { echo -e "${yellow}[!] $*${reset}"; }
error() { echo -e "${red}[E] $*${reset}"; }
debug() { if [[ "${DEBUG}" == "true" ]]; then echo -e "${grey}[D] $*${reset}"; fi }
success() { echo -e "${green}[✔] $*${reset}"; }
fail() { echo -e "${red}[🞨] $*${reset}"; }
