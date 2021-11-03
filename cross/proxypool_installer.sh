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

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options

# proxypool
# https://github.com/Sansui233/proxypool
APP_INSTALL_NAME="proxypool"
GITHUB_REPO_NAME="Sansui233/proxypool"

ARCHIVE_EXT="gz"
ARCHIVE_EXEC_NAME="proxypool"

EXEC_INSTALL_PATH="/usr/local/bin"
EXEC_INSTALL_NAME="proxypool"

[[ -z "${ARCHIVE_EXEC_NAME}" ]] && ARCHIVE_EXEC_NAME="${EXEC_INSTALL_NAME}"

DOWNLOAD_FILENAME="${WORKDIR}/${EXEC_INSTALL_NAME}"
[[ -n "${ARCHIVE_EXT}" ]] && DOWNLOAD_FILENAME="${DOWNLOAD_FILENAME}.${ARCHIVE_EXT}"

REMOTE_SUFFIX=""
REMOTE_FILENAME=""

IS_INSTALL="yes"
IS_UPDATE="no"

CURRENT_VERSION="0.0.0"
# VERSION_FILENAME=""
VERSION_FILENAME="${EXEC_INSTALL_PATH}/${EXEC_INSTALL_NAME}.version"

if [[ -x "$(command -v ${EXEC_INSTALL_NAME})" ]]; then
    IS_UPDATE="yes"
    [[ -s "${VERSION_FILENAME}" ]] && CURRENT_VERSION=$(head -n1 "${VERSION_FILENAME}")
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && IS_INSTALL="no"
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${APP_INSTALL_NAME}${BLUE}..."

    CHECK_URL="https://api.github.com/repos/${GITHUB_REPO_NAME}/releases/latest"
    REMOTE_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" "${CHECK_URL}" | grep 'tag_name' | cut -d\" -f4 | cut -d'v' -f2)
    if version_le "${REMOTE_VERSION}" "${CURRENT_VERSION}"; then
        IS_INSTALL="no"
    fi
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    [[ -z "${OS_INFO_TYPE}" ]] && get_os_type
    [[ -z "${OS_INFO_ARCH}" ]] && get_arch

    REMOTE_FILENAME="${EXEC_INSTALL_NAME}-${OS_INFO_TYPE}-${OS_INFO_ARCH}-v${REMOTE_VERSION}.${ARCHIVE_EXT}"
    case "${OS_INFO_ARCH}" in
        arm64)
            REMOTE_FILENAME="${EXEC_INSTALL_NAME}-${OS_INFO_TYPE}-armv8-v${REMOTE_VERSION}.${ARCHIVE_EXT}"
            ;;
        arm)
            REMOTE_FILENAME="${EXEC_INSTALL_NAME}-${OS_INFO_TYPE}-armv7-v${REMOTE_VERSION}.${ARCHIVE_EXT}"
            ;;
    esac

    [[ -z "${REMOTE_FILENAME}" ]] && IS_INSTALL="no"
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${APP_INSTALL_NAME} ${YELLOW}${REMOTE_VERSION}${BLUE}..."

    # Download file
    DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/${GITHUB_REPO_NAME}/releases/download/v${REMOTE_VERSION}/${REMOTE_FILENAME}"
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
        # Extract file
        case "${ARCHIVE_EXT}" in
            "zip")
                unzip -qo "${DOWNLOAD_FILENAME}" -d "${WORKDIR}"
                ;;
            "tar.bz2")
                tar -xjf "${DOWNLOAD_FILENAME}" -C "${WORKDIR}"
                ;;
            "tar.gz")
                tar -xzf "${DOWNLOAD_FILENAME}" -C "${WORKDIR}"
                ;;
            "tar.xz")
                tar -xJf "${DOWNLOAD_FILENAME}" -C "${WORKDIR}"
                ;;
            "gz")
                cd "${WORKDIR}" && gzip -df "${DOWNLOAD_FILENAME}"
                ;;
            "bz")
                cd "${WORKDIR}" && bzip2 -df "${DOWNLOAD_FILENAME}"
                ;;
            "7z")
                7z e "${DOWNLOAD_FILENAME}" -o"${WORKDIR}"
                ;;
        esac

        # Install
        [[ -z "${ARCHIVE_EXEC_NAME}" ]] && ARCHIVE_EXEC_NAME="${EXEC_INSTALL_NAME}"

        if [[ -s "${WORKDIR}/${ARCHIVE_EXEC_NAME}" ]]; then
            sudo cp -f "${WORKDIR}/${ARCHIVE_EXEC_NAME}" "${EXEC_INSTALL_PATH}/${EXEC_INSTALL_NAME}" && \
                sudo chmod +x "${EXEC_INSTALL_PATH}/${EXEC_INSTALL_NAME}" && \
                [[ -n "${VERSION_FILENAME}" ]] && echo "${REMOTE_VERSION}" | sudo tee "${VERSION_FILENAME}" >/dev/null || true
        fi
    fi
fi


# config
if [[ ! -s "/etc/proxypool/config.yaml" ]]; then
    mkdir -p "/etc/proxypool" && \
        curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${WORKDIR}/source.yaml" \
            "https://raw.githubusercontent.com/Sansui233/proxypool/master/config/source.yaml" && \
        curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${WORKDIR}/config.yaml" \
            "https://raw.githubusercontent.com/Sansui233/proxypool/master/config/config.yaml" && \
        sudo cp -f "${WORKDIR}/source.yaml" "/etc/proxypool/source.yaml" && \
        sudo cp -f "${WORKDIR}/config.yaml" "/etc/proxypool/config.yaml" && \
        sudo sed -i "s|./config/source.yaml|/etc/proxypool/source.yaml|" "/etc/proxypool/config.yaml"
fi

# sudo sed -i "s|domain:.*|domain: pool.example.com|" "/etc/proxypool/config.yaml"
# Install_systemd_Service "proxypool" "/usr/local/bin/proxypool -c /etc/proxypool/config.yaml"

## nginx
# proxy_pass http://127.0.0.1:12580/;


cd "${CURRENT_DIR}" || exit