#!/usr/bin/env bash

grey="\\e[37m"
blue="\\e[36m"
red="\\e[31m"
green="\\e[32m"
reset="\\e[0m"

GITHUB_USER=thesandybridge
GITHUB_REPO=$1
BINARY=$2
LOCAL_PATH=~/.local/bin

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
EOM

# Logging, loosely based on http://www.ludovicocaldara.net/dba/bash-tips-4-use-logging-levels/
info() { echo -e "${blue}[+] $*${reset}"; }
error() { echo -e "${red}[E] $*${reset}"; }
debug() { if [[ "${DEBUG}" == "true" ]]; then echo -e "${grey}[D] $*${reset}"; fi }
success() { echo -e "${green}[✔] $*${reset}"; }
fail() { echo -e "${red}[✖] $*${reset}"; }

if [[ -z $1 ]]; then
    fail "No repository provided"
    exit 1
fi


if [[ -z $2 ]]; then
    fail "No binary name provided"
    exit 1
fi

info "Fetching binary from github.com/${GITHUB_USER}/${GITHUB_REPO}..."
download_linux=$(curl -s https://api.github.com/repos/${GITHUB_USER}/${GITHUB_REPO}/releases/latest \
| grep "browser_download_url.*amd64"  \
| cut -d : -f 2,3 \
| tr -d \" \
| xargs)

info "Downloading binary..."
wget -nv $download_linux -O $LOCAL_PATH/$BINARY

info "Creating executable..."
chmod +x $LOCAL_PATH/$BINARY

success "Success! Binary has been added to $LOCAL_PATH"

