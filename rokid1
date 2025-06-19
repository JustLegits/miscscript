#!/data/data/com.termux/files/usr/bin/bash

# Setup TERMUX_APP_PACKAGE_MANAGER
source "/data/data/com.termux/files/usr/bin/termux-setup-package-manager" || exit 1

MIRROR_BASE_DIR="/data/data/com.termux/files/usr/etc/termux/mirrors"

if [ "$1" == "--help" ] || [ "$1" == "-help" ]; then
    echo "Script for choosing a group of mirrors to use."
    echo "All mirrors are listed at"
    echo "https://github.com/termux/termux-packages/wiki/Mirrors"
    exit 0
fi

unlink_and_link() {
    MIRROR_GROUP="$1"
    if [ -L "/data/data/com.termux/files/usr/etc/termux/chosen_mirrors" ]; then
        unlink "/data/data/com.termux/files/usr/etc/termux/chosen_mirrors"
    fi
    ln -s "${MIRROR_GROUP}" "/data/data/com.termux/files/usr/etc/termux/chosen_mirrors"
}

select_repository_group() {
    unlink_and_link ${MIRROR_BASE_DIR}/all
}

get_mirror_url() {
    basename "$1"
}

get_mirror_description() {
    head -n 2 "$1" | tail -n 1 | cut -d" " -f2-
}

usage() {
   echo "Usage: termux-change-repo"
   echo ""
   echo "termux-change-repo is a utility used to simplify which mirror(s)"
   echo "pkg (our apt wrapper) should use."
}

if [ $# -gt 0 ]; then
    usage
fi

if ! command -v apt 1>/dev/null; then
    echo "Error: Cannot change mirrors since apt is not installed." >&2
    exit 1
fi

if [ "$TERMUX_APP_PACKAGE_MANAGER" = "pacman" ]; then
    read -p "Warning: termux-change-repo can only change mirrors for apt, is that what you intended? [y|n] " -n 1 -r
    echo
    [[ ${REPLY} =~ ^[Nn]$ ]] && exit
fi

mkdir -p "/data/data/com.termux/files/usr/tmp" || exit $?

select_repository_group

echo "[*] pkg --check-mirror update"
TERMUX_APP_PACKAGE_MANAGER=apt pkg --check-mirror update
