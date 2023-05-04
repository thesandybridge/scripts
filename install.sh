#!/usr/bin/env bash
# thesandybridge's binary installer.
#
# This script is used to fetch the latest release page from a repository,
# it then filters out the ame64 binary and uses wget to install it to the machine.
#
# The location of the binary should be in ~/.local/bin and it will first check
# to see if path exists, creating it if it doesn't.
#
# This script does not add it to the $PATH variable, so the user will need to
# manually add it.

set -e

# DEFINE VARIABLES
grey="\\e[37m"
blue="\\e[36m"
red="\\e[31m"
yellow="\\e[33m"
green="\\e[32m"
reset="\\e[0m"

GITHUB_USER=thesandybridge
GITHUB_REPO=$1
BINARY=$2
DEBUG=$3
LOCAL_PATH=$HOME/.local/bin
RELEASE_URL=https://api.github.com/repos/${GITHUB_USER}/${GITHUB_REPO}/releases/latest

cat << "EOM"
┃┃┃┃┃┃┃┃┃┃┃┃┏┓┃┃┃┃┓┃┃┃┃┃┃┏┓┃┃┃┃┃┃
┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃
┏━━┓━━┓┃━┓┃━┛┃┓┃┏┓┗━┓━┓┓━┛┃━━┓━━┓
┃━━┫┃┓┃┃┏┓┓┏┓┃┃┃┃┃┏┓┃┏┛┫┏┓┃┏┓┃┏┓┃
┣━━┃┗┛┗┓┃┃┃┗┛┃┗━┛┃┗┛┃┃┃┃┗┛┃┗┛┃┃━┫
┗━━┛━━━┛┛┗┛━━┛━┓┏┛━━┛┛┃┛━━┛━┓┃━━┛
┃┃┃┃┃┃┃┃┃┃┃┃┃┃━┛┃┃┃┃┃┃┃┃┃┃┃━┛┃┃┃┃
┃┃┃┃┃┃┃┃┃┃┃┃┃┃━━┛┃┃┃┃┃┃┃┃┃┃━━┛┃┃┃
    Custom Binary Installer
https://github.com/thesandybridge
---------------------------------
EOM

function shutdown() {
  tput cnorm # reset cursor
}
trap shutdown EXIT

# Logging, loosely based on http://www.ludovicocaldara.net/dba/bash-tips-4-use-logging-levels/
info() { echo -e "${blue}[+] $*${reset}"; }
warn() { echo -e "${yellow}[!] $*${reset}"; }
error() { echo -e "${red}[E] $*${reset}"; }
debug() { if [[ "${DEBUG}" == "true" ]]; then echo -e "${grey}[D] $*${reset}"; fi }
success() { echo -e "${green}[✔] $*${reset}"; }
fail() { echo -e "${red}[🞨] $*${reset}"; }

curl_args=
wget_args=
enable_debug() {
    if [[ "${DEBUG}" == "true" ]]; then
        warn "Enabling debug mode."
        set -x
        curl_args="-v"
        wget_args="-v"
    else
        curl_args="-s"
        wget_args="-q"
    fi
}

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

check_local_dir() {
    info "Checking for $LOCAL_PATH"

    if [[ ! -d "$LOCAL_PATH" ]]; then
        mkdir -p $LOCAL_PATH
        debug "$LOCAL_PATH not found, attempting to create..."
        success "Created $LOCAL_PATH directory"
    else
        debug "$LOCAL_PATH found, continuing..."
    fi

    info "Checking if $LOCAL_PATH is in PATH"
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        debug "Adding $LOCAL_PATH to \$PATH"
        echo 'export PATH=$PATH:$HOME/.local/bin' >> ~/.bashrc
        debug "Sourcing .bashrc..."
        source ~/.bashrc
    fi
}

validate_args() {
    # Check for first argument, should be a valid github repository name
    debug "Checking for script arguments."

    if [[ -z $GITHUB_REPO ]]; then
        debug "Missing first argument."
        fail "No repository provided"
        exit 1
    fi

    # check for second argument, this will be the name of the program
    if [[ -z $BINARY ]]; then
        debug "Missing second argument."
        fail "No binary name provided"
        exit 1
    fi
}

install() {
    debug "Fetching binary from github.com/${GITHUB_USER}/${GITHUB_REPO}..."
    get_url=$(curl $curl_args $RELEASE_URL \
        | grep "browser_download_url.*amd64"  \
        | cut -d : -f 2,3 \
        | tr -d \" \
        | xargs > /tmp/_out ) &
    spinner $! "Fetching binary from github.com/${GITHUB_USER}/${GITHUB_REPO}..."
    download_url=$(</tmp/_out)

    debug "Fetching binary from $download_linux"
    wget $wget_args $download_url -O $LOCAL_PATH/$BINARY &
    spinner $! "Downloading binary..."

    debug "Creating executable at $LOCAL_PATH"
    chmod +x $LOCAL_PATH/$BINARY &
    spinner $! "Creating executable..."

    success "Success! Binary has been added to $LOCAL_PATH"
    warn "You may need to add $LOCAL_PATH to your \$PATH"
}

check_local_dir
enable_debug
validate_args
install
