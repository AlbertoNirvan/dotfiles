#!/usr/bin/env bash

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
[[ -z "${CURRENT_DIR}" || ! -d "${CURRENT_DIR}" ]] && CURRENT_DIR=$(pwd)

[[ -z "${MY_SHELL_SCRIPTS}" ]] && MY_SHELL_SCRIPTS="$HOME/.dotfiles"

# Load custom functions
if type 'colorEcho' 2>/dev/null | grep -q 'function'; then
    :
else
    if [[ -s "${MY_SHELL_SCRIPTS}/custom_functions.sh" ]]; then
        source "${MY_SHELL_SCRIPTS}/custom_functions.sh"
    else
        echo "${MY_SHELL_SCRIPTS}/custom_functions.sh does not exist!"
        exit 0
    fi
fi

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options

[[ -z "${OS_INFO_TYPE}" ]] && get_os_type
[[ -z "${OS_INFO_ARCH}" ]] && get_arch

# goproxy
# https://github.com/snail007/goproxy
[[ -s "${MY_SHELL_SCRIPTS}/installer/goproxy_installer.sh" ]] && source "${MY_SHELL_SCRIPTS}/installer/goproxy_installer.sh"


# shadowtunnel
# https://github.com/snail007/shadowtunnel
colorEcho "${BLUE}Checking latest version for ${FUCHSIA}shadowtunnel${BLUE}..."

CHECK_URL="https://api.github.com/repos/snail007/shadowtunnel/releases/latest"
REMOTE_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" "${CHECK_URL}" | grep 'tag_name' | cut -d\" -f4)

if [[ -n "$REMOTE_VERSION" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}shadowtunnel ${YELLOW}${REMOTE_VERSION}${BLUE}..."

    DOWNLOAD_FILENAME="${WORKDIR}/shadowtunnel.tar.gz"
    DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/snail007/shadowtunnel/releases/download/$REMOTE_VERSION/shadowtunnel-${OS_INFO_TYPE}-${OS_INFO_ARCH}.tar.gz"
    colorEcho "${BLUE}  From ${ORANGE}${DOWNLOAD_URL}"
    curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"

    curl_download_status=$?
    if [[ ${curl_download_status} -gt 0 && -n "${GITHUB_DOWNLOAD_URL}" ]]; then
        DOWNLOAD_URL="${DOWNLOAD_URL//${GITHUB_DOWNLOAD_URL}/https://github.com}"
        colorEcho "${BLUE}  From ${ORANGE}${DOWNLOAD_URL}"
        curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"
        curl_download_status=$?
    fi

    if [[ ${curl_download_status} -eq 0 ]]; then
        tar -xzf "${DOWNLOAD_FILENAME}" -C "/usr/local/bin" && \
        chmod +x "/usr/local/bin/shadowtunnel"
    fi
fi

# How to use
## start a http proxy on vps listening on :38080
# proxy http -p "127.0.0.1:38080" --daemon

## start a tunnel on vps listening on :50000 and forward to 127.0.0.1:38080
# shadowtunnel -e -f "127.0.0.1:38080" -l :50000 -p "your-password" -daemon -forever -log "/var/log/shadowtunnel.log"

## start a tunnel on local machine listening on tcp :50000 and forward to udp :50000
# shadowtunnel -U -E -f "[Reomte-IP]:50000" -l :50000 -p "your-password"

## set http proxy configuration in chrome
## setting local chrome's http proxy configuration as below：
# ip: 127.0.0.1 port: 50000

