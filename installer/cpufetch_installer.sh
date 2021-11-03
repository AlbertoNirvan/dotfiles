#!/usr/bin/env bash

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
[[ -z "${CURRENT_DIR}" || ! -d "${CURRENT_DIR}" ]] && CURRENT_DIR=$(pwd)

# Load custom functions
if type 'colorEcho' 2>/dev/null | grep -q 'function'; then
    :
else
    if [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/custom_functions.sh" ]]; then
        source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/custom_functions.sh"
    else
        echo "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/custom_functions.sh does not exist!"
        exit 0
    fi
fi

# https://github.com/Dr-Noob/cpufetch
IS_INSTALL="yes"
[[ "${IS_UPDATE_ONLY}" == "yes" ]] && IS_INSTALL="no"

if [[ "${IS_INSTALL}" == "yes" ]]; then
    Git_Clone_Update_Branch "Dr-Noob/cpufetch" "${WORKDIR}/cpufetch" && \
        cd "${WORKDIR}/cpufetch" && \
        make && \
        sudo cp "${WORKDIR}/cpufetch/cpufetch" "/usr/local/bin/cpufetch" && \
        sudo chmod +x "/usr/local/bin/cpufetch"
fi

cd "${CURRENT_DIR}" || exit