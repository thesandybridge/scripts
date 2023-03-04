#!/usr/bin/env bash

set -e

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
LOCAL_PATH=~/.local/bin
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

# Logging, loosely based on http://www.ludovicocaldara.net/dba/bash-tips-4-use-logging-levels/
info() { echo -e "${blue}[+] $*${reset}"; }
warn() { echo -e "${yellow}[!] $*${reset}"; }
error() { echo -e "${red}[E] $*${reset}"; }
debug() { if [[ "${DEBUG}" == "true" ]]; then echo -e "${grey}[D] $*${reset}"; fi }
success() { echo -e "${green}✔ $*${reset}"; }
fail() { echo -e "${red}✖ $*${reset}"; }

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

check_local_dir() {
    info "Checking for $LOCAL_PATH"

    if [[ ! -d "~/.local/bin" ]]; then
        mkdir -p ~/.local/bin
        warn "Created ~/.local/bin directory"
    fi
}

validate_args() {
    # Check for first argument, should be a valid github repository name
    if [[ -z $GITHUB_REPO ]]; then
        fail "No repository provided"
        exit 1
    fi

    # check for second argument, this will be the name of the program
    if [[ -z $BINARY ]]; then
        fail "No binary name provided"
        exit 1
    fi
}

install() {
    info "Fetching binary from github.com/${GITHUB_USER}/${GITHUB_REPO}..."
    download_linux=$(curl $curl_args $RELEASE_URL \
        | grep "browser_download_url.*amd64"  \
        | cut -d : -f 2,3 \
        | tr -d \" \
        | xargs)

    info "Downloading binary..."
    wget $wget_args $download_linux -O $LOCAL_PATH/$BINARY

    info "Creating executable..."
    chmod +x $LOCAL_PATH/$BINARY

    success "Success! Binary has been added to $LOCAL_PATH"
}

check_local_dir
enable_debug
validate_args
install
