#!/usr/bin/env bash

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || "${WORKDIR}" != "/tmp/"* || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
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

App_Installer_Reset

# skim - Fuzzy Finder in rust
# https://github.com/lotabout/skim
APP_INSTALL_NAME="skim"
GITHUB_REPO_NAME="lotabout/skim"

EXEC_INSTALL_NAME="sk"

ARCHIVE_EXT="tar.gz"
ARCHIVE_EXEC_NAME="sk"

INSTALL_FROM_SOURCE="no"
EXEC_FULL_NAME=""

CURRENT_VERSION="0.0.0"

if [[ -x "$(command -v ${EXEC_INSTALL_NAME})" ]]; then
    IS_UPDATE="yes"
    CURRENT_VERSION=$(${EXEC_INSTALL_NAME} --version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    EXEC_FULL_NAME=$(which ${EXEC_INSTALL_NAME})
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && IS_INSTALL="no"
fi

# if ! App_Installer_Install; then
#     colorEcho "${RED}  Install ${FUCHSIA}${APP_INSTALL_NAME}${RED} failed!"
# fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${APP_INSTALL_NAME}${BLUE}..."

    CHECK_URL="https://api.github.com/repos/${GITHUB_REPO_NAME}/releases/latest"
    App_Installer_Get_Remote_Version "${CHECK_URL}"
    if version_le "${REMOTE_VERSION}" "${CURRENT_VERSION}"; then
        IS_INSTALL="no"
    fi
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    if ! checkPackageInstalled "${APP_INSTALL_NAME}"; then
        [[ -x "$(command -v cargo)" || -x "$(command -v brew)" ]] && INSTALL_FROM_SOURCE="yes"
    fi
fi

if [[ "${INSTALL_FROM_SOURCE}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${APP_INSTALL_NAME} ${YELLOW}${REMOTE_VERSION}${BLUE}..."
    # From source on crates.io
    [[ -x "$(command -v cargo)" ]] && cargo install "${APP_INSTALL_NAME}"

    # Install via Homebrew
    [[ ! -x "$(command -v cargo)" && -x "$(command -v brew)" ]] && brew install "sk"
elif [[ "${INSTALL_FROM_SOURCE}" == "no" ]]; then
    if checkPackageNeedInstall "${APP_INSTALL_NAME}"; then
        colorEcho "${BLUE}  Installing ${FUCHSIA}${APP_INSTALL_NAME} ${YELLOW}${REMOTE_VERSION}${BLUE}..."
        [[ -x "$(command -v pacman)" ]] && sudo pacman --noconfirm -S "${APP_INSTALL_NAME}"
    fi
fi

cd "${CURRENT_DIR}" || exit
