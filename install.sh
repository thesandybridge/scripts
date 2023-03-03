#!/usr/bin/env bash

BLUE="34"
YELLOW="33"
MAGENTA="35"
RED="31"
BOLDBLUE="\e[1;${BLUE}m"
BOLDYELLOW="\e[1;${YELLOW}m"
BOLDMAGENTA="\e[1;${MAGENTA}m"
BOLDRED="\e[1;${RED}m"
ENDCOLOR="\e[0m"

GITHUB_USER=thesandybridge
GITHUB_REPO=$1
BINARY=$2
LOCAL_PATH=~/.local/bin

if [[ -z $1 ]]; then
    echo -e "${BOLDRED}[E]${ENDCOLOR} No repository provided"
    exit 1
fi


if [[ -z $2 ]]; then
    echo -e "${BOLDRED}[E]${ENDCOLOR} No binary name provided"
    exit 1
fi

echo -e "${BOLDBLUE}[+]${ENDCOLOR} Downloading file from github.com/${GITHUB_USER}/${GITHUB_REPO}..."

download_linux=$(curl -s https://api.github.com/repos/${GITHUB_USER}/${GITHUB_REPO}/releases/latest \
| grep "browser_download_url.*amd64"  \
| cut -d : -f 2,3 \
| tr -d \" \
| xargs)

wget $download_linux -O $LOCAL_PATH/$BINARY && chmod +x $LOCAL_PATH/$BINARY

