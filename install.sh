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

COMMON_SH="/tmp/common.sh"
if [ ! -f "$COMMON_SH" ]; then
    curl -sSL https://scripts.sandybridge.io/common.sh -o "$COMMON_SH"
fi
source "$COMMON_SH"

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

        if ! grep -q 'export PATH="$PATH"' ~/.bashrc; then
            echo 'export PATH="$PATH"' >> ~/.bashrc
            echo 'Added export PATH="$PATH" to ~/.bashrc'
        fi

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
    platform="$(uname -s)"
    arch="$(uname -m)"

    case "$platform" in
        Darwin)   platform="apple-darwin" ;;
        Linux)    platform="unknown-linux-gnu" ;;
        MINGW*|MSYS*|CYGWIN*|Windows_NT) platform="pc-windows-msvc" ;;
        *)        fail "Unsupported platform: $platform"; exit 1 ;;
    esac

    case "$arch" in
        x86_64|amd64)
            arch="x86_64"
            ;;
        arm64|aarch64)
            if [[ "$platform" == "apple-darwin" ]]; then
                warn "Apple Silicon detected — falling back to x86_64 binary (Rosetta)"
                arch="x86_64"
            else
                arch="aarch64"
            fi
            ;;
        *)
            fail "Unsupported architecture: $arch"
            exit 1
            ;;
    esac

    tarball="${GITHUB_REPO}-${arch}-${platform}.tar.gz"
    binary_legacy="${GITHUB_REPO}_amd64"

    info "Trying to find asset: $tarball"

    download_url=$(curl $curl_args "$RELEASE_URL" | jq -r ".assets[] | select(.name == \"$tarball\") | .browser_download_url")

    if [[ -n "$download_url" ]]; then
        tmp_dir=$(mktemp -d)
        info "Downloading $tarball..."
        wget $wget_args "$download_url" -O "$tmp_dir/$tarball" &
        spinner $! "Downloading archive..."

        info "Extracting $tarball..."
        tar -xf "$tmp_dir/$tarball" -C "$tmp_dir" &
        spinner $! "Extracting..."

        if [[ ! -f "$tmp_dir/$BINARY" ]]; then
            fail "Archive does not contain expected binary: $BINARY"
            exit 1
        fi

        mv "$tmp_dir/$BINARY" "$LOCAL_PATH/$BINARY"
        chmod +x "$LOCAL_PATH/$BINARY"
        rm -rf "$tmp_dir"
        success "Installed $BINARY from tarball to $LOCAL_PATH"
        return 0
    fi

    warn "Tarball not found. Falling back to legacy format: $binary_legacy"

    legacy_url=$(curl $curl_args "$RELEASE_URL" | jq -r ".assets[] | select(.name == \"$binary_legacy\") | .browser_download_url")

    if [[ -z "$legacy_url" ]]; then
        fail "No binary found for $platform/$arch in either format."
        exit 1
    fi

    info "Downloading legacy binary..."
    wget $wget_args "$legacy_url" -O "$LOCAL_PATH/$BINARY" &
    spinner $! "Downloading legacy binary..."

    chmod +x "$LOCAL_PATH/$BINARY"
    success "Installed $BINARY from legacy format to $LOCAL_PATH"
}

enable_debug
check_local_dir
validate_args
install
source ~/.bashrc
