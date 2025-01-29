#!/usr/bin/env bash

set -euo pipefail

NORMAL="\e[0m"
ERROR="\e[31m"
SUCCESS="\e[32m"
WARNING="\e[33m"
PRIMARY="\e[34m"

exit_error() {
    echo -e "${ERROR}ERROR:${NORMAL} $1" >&2
    exit 1
}

exit_success() {
    echo -e "${SUCCESS}SUCCESS:${NORMAL} $1"
    exit 0
}

exit_warning() {
    echo -e "${WARNING}WARNING:${NORMAL} $1" >&2
    exit 1
}

if [[ $EUID -ne 0 ]]; then
    exit_warning "This script must be run as root."
fi

if [[ ! -f "/etc/os-release" ]]; then
    exit_warning "File /etc/os-release not found."
fi

if [[ ! -r "/etc/os-release" ]]; then
    exit_warning "File /etc/os-release not readable."
fi

check_cmd() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        exit_warning "Command '$cmd' not found. Please install it and retry."
    fi
}

check_cmd "curl"
check_cmd "dpkg"
check_cmd "apt-get"

run_cmd() {
    local action="$1"
    shift

    local error="$1"
    shift

    echo -en "${PRIMARY}ACTION:${NORMAL} $action"

    set +e
    local output
    output=$("$@" 2>&1)
    local status=$?
    set -e

    if [ "$status" -eq 0 ]; then
        echo -e "${SUCCESS}DONE${NORMAL}"
    else
        echo
        echo "$output"
        exit_error "$error"
    fi
}

source "/etc/os-release"

PKG_NAME="powershell"
DEB_NAME="packages-microsoft-prod.deb"
DEB_LINK="https://packages.microsoft.com/config/ubuntu/$VERSION_ID/$DEB_NAME"

run_cmd "Downloading $DEB_NAME package... " \
    "Failed to download $DEB_NAME package." \
    curl -fsLS "$DEB_LINK" -o "/tmp/$DEB_NAME"

run_cmd "Installing $DEB_NAME package... " \
    "Failed to install $DEB_NAME package." \
    dpkg -i "/tmp/$DEB_NAME"

run_cmd "Removing $DEB_NAME package... " \
    "Failed to remove $DEB_NAME package." \
    rm -f "/tmp/$DEB_NAME"

run_cmd "Updating package list... " \
    "Failed to update package list." \
    apt-get update -qq

run_cmd "Installing $PKG_NAME... " \
    "Failed to install $PKG_NAME." \
    apt-get install -qq "$PKG_NAME"

exit_success "$PKG_NAME has been installed successfully."
