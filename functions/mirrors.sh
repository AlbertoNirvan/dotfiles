#!/usr/bin/env bash

# docker
function setMirrorDocker() {
    if [[ -x "$(command -v docker)" ]]; then
        if [[ -z "${MIRROR_DOCKER_REGISTRY}" ]]; then
            MIRROR_DOCKER_REGISTRY='"https://docker.mirrors.sjtug.sjtu.edu.cn","https://docker.nju.edu.cn/","https://hub-mirror.c.163.com"'
        fi
    fi
}

# homebrew
function setMirrorHomebrew() {
    if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
        export HOMEBREW_BREW_GIT_REMOTE=${HOMEBREW_BREW_GIT_REMOTE:-"https://mirrors.ustc.edu.cn/brew.git"}
        export HOMEBREW_CORE_GIT_REMOTE=${HOMEBREW_CORE_GIT_REMOTE:-"https://mirrors.ustc.edu.cn/homebrew-core.git"}
        export HOMEBREW_BOTTLE_DOMAIN=${HOMEBREW_BOTTLE_DOMAIN:-"https://mirrors.ustc.edu.cn/homebrew-bottles"}
        export HOMEBREW_API_DOMAIN=${HOMEBREW_API_DOMAIN:-"https://mirrors.ustc.edu.cn/homebrew-bottles/api"}

        ## Brew installation fails due to Ruby versioning?
        ## https://unix.stackexchange.com/questions/694020/brew-installation-fails-due-to-ruby-versioning
        # export RUBY_BUILD_MIRROR_URL=${RUBY_BUILD_MIRROR_URL:-"https://cache.ruby-china.com"}
        # export RUBY_GEM_SOURCE_MIRROR=${RUBY_GEM_SOURCE_MIRROR:-"https://gems.ruby-china.com/"}
    fi
}

# go: installer/goup_go_installer.sh, installer/gvm_go_installer.sh
function setMirrorGo() {
    local GO_VERSION

    # goup
    if [[ -x "$(command -v goup)" ]]; then
        export GOUP_GO_HOST=${GOUP_GO_HOST:-"golang.google.cn"}
    fi

    # go
    if [[ -x "$(command -v go)" ]]; then
        GO_VERSION=$(go version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
        if version_ge "${GO_VERSION}" '1.13'; then
            go env -w GOPROXY="${MIRROR_GO_PROXY:-"https://goproxy.cn,direct"}"
            go env -w GOSUMDB="${MIRROR_GO_SUMDB:-"sum.golang.google.cn"}"
            # https://goproxy.io/zh/docs/goproxyio-private.html
            [[ -n "${MIRROR_GO_PRIVATE}" ]] && go env -w GOPRIVATE="${MIRROR_GO_PRIVATE}"
        else
            export GOPROXY=${MIRROR_GO_PROXY:-"https://goproxy.cn,direct"}
            export GOSUMDB=${MIRROR_GO_SUMDB:-"sum.golang.google.cn"}
            [[ -n "${MIRROR_GO_PRIVATE}" ]] && export GOPRIVATE="${MIRROR_GO_PRIVATE}"
        fi
    fi
}

# flutter
function setMirrorFlutter() {
    if [[ -x "$(command -v flutter)" ]]; then
        export PUB_HOSTED_URL=${PUB_HOSTED_URL:-"https://pub.flutter-io.cn"}
        export FLUTTER_STORAGE_BASE_URL=${FLUTTER_STORAGE_BASE_URL:-"https://storage.flutter-io.cn"}
    fi
}

# rustup & cargo
function setMirrorRust() {
    export RUSTUP_DIST_SERVER=${RUSTUP_DIST_SERVER:-"https://rsproxy.cn"}
    export RUSTUP_UPDATE_ROOT=${RUSTUP_UPDATE_ROOT:-"https://rsproxy.cn/rustup"}

    # cargo
    MIRROR_RUST_CARGO=${MIRROR_RUST_CARGO:-"rsproxy-sparse"}
    if [[ ! -s "$HOME/.cargo/config" ]]; then
        mkdir -p "$HOME/.cargo"
        cp "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/conf/cargo.toml" "$HOME/.cargo/config"
        sed -i -e "s|'crates-io-sparse'|'${MIRROR_RUST_CARGO}'|g" "$HOME/.cargo/config"
    fi
}

# nodejs & nvm & nvs
function setMirrorNodejs() {
    # nodejs
    if [[ "$(command -v node)" ]]; then
        export MIRROR_NODEJS_REGISTRY=${MIRROR_NODEJS_REGISTRY:-"https://registry.npmmirror.com"}
    fi

    # nvm
    if [[ "$(command -v nvm)" ]]; then
        export NVM_NODEJS_ORG_MIRROR=${NVM_NODEJS_ORG_MIRROR:-"https://npmmirror.com/mirrors/node"}
    fi

    # nvs
    if [[ "$(command -v nvs)" ]]; then
        export NVS_NODEJS_ORG_MIRROR=${NVS_NODEJS_ORG_MIRROR:-"https://npmmirror.com/mirrors/node"}
        nvs remote node "${NVS_NODEJS_ORG_MIRROR}"
    fi
}

# nodejs: nodejs/nvm_node_installer.sh, nodejs/nvs_node_installer.sh
function setMirrorNpm() {
    if [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/nodejs/npm_config.sh" ]]; then
        "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/nodejs/npm_config.sh" AUTO
    fi
}

# pip
function setMirrorPip() {
    if [[ -x "$(command -v pip)" ]]; then
        export PYTHON_PIP_CONFIG=${PYTHON_PIP_CONFIG:-"$HOME/.pip/pip.conf"}
        export MIRROR_PYTHON_PIP_URL=${MIRROR_PYTHON_PIP_URL:-"https://mirrors.aliyun.com/pypi/simple/"}
        export MIRROR_PYTHON_PIP_HOST=${MIRROR_PYTHON_PIP_HOST:-"mirrors.aliyun.com"}
    fi
}

# conda
function setMirrorConda() {
    if [[ "$(command -v conda)" ]]; then
        export MIRROR_PYTHON_CONDA=${MIRROR_PYTHON_CONDA:-"https://mirrors.bfsu.edu.cn"}

        if [[ ! -s "$HOME/.condarc" ]]; then
            cp "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/conf/condarc" "$HOME/.condarc"
            sed -i -e "s|https://mirrors.bfsu.edu.cn|${MIRROR_PYTHON_CONDA}|g" "$HOME/.condarc"
        fi
    fi
}

# rbenv
function setMirrorRbenv() {
    if [[ -x "$(command -v rbenv)" ]]; then
        export RUBY_BUILD_MIRROR_URL=${RUBY_BUILD_MIRROR_URL:-"https://cache.ruby-china.com"}
    fi
}

# gem mirror
function setMirrorGem() {
    if [[ -x "$(command -v gem)" || -x "$(command -v bundle)" ]]; then
        export RUBY_GEM_SOURCE_MIRROR=${RUBY_GEM_SOURCE_MIRROR:-"https://gems.ruby-china.com/"}

        if [[ -x "$(command -v gem)" ]]; then
            gem sources --add "${RUBY_GEM_SOURCE_MIRROR}" --remove "https://rubygems.org/"
            gem sources -l
        fi

        if [[ -x "$(command -v bundle)" ]]; then
            bundle config mirror.https://rubygems.org "${RUBY_GEM_SOURCE_MIRROR}"
            bundle config list
        fi
    fi
}


# unset all mirrors
function unsetMirrorAll() {
    # docker
    unset MIRROR_DOCKER_REGISTRY
    # homebrew
    unset HOMEBREW_BREW_GIT_REMOTE
    unset HOMEBREW_CORE_GIT_REMOTE
    unset HOMEBREW_BOTTLE_DOMAIN
    unset HOMEBREW_API_DOMAIN
    # goup
    unset GOUP_GO_HOST
    # go
    unset MIRROR_GO_PROXY
    unset MIRROR_GO_SUMDB
    unset MIRROR_GO_PRIVATE
    if [[ -x "$(command -v go)" ]]; then
        go env -u GOPROXY
        go env -u GOSUMDB
        go env -u GOPRIVATE
    fi
    # flutter
    unset PUB_HOSTED_URL
    unset FLUTTER_STORAGE_BASE_URL
    # rustup & cargo
    unset RUSTUP_DIST_SERVER
    unset RUSTUP_UPDATE_ROOT
    unset MIRROR_RUST_CARGO
    [[ -s "$HOME/.cargo/config" ]] && rm -f "$HOME/.cargo/config"
    # python
    unset PYTHON_PIP_CONFIG
    unset MIRROR_PYTHON_PIP_URL
    unset MIRROR_PYTHON_PIP_HOST
    # conda
    unset MIRROR_PYTHON_CONDA
    [[ -s "$HOME/.condarc" ]] && rm -f "$HOME/.condarc"
    # rbenv
    [[ -x "$(command -v gem)" ]] && gem sources --add "https://rubygems.org/" --remove "${RUBY_GEM_SOURCE_MIRROR}"
    [[ -x "$(command -v bundle)" ]] && bundle config unset mirror.https://rubygems.org
    unset RUBY_BUILD_MIRROR_URL
    unset RUBY_GEM_SOURCE_MIRROR
    # nodejs
    unset MIRROR_NODEJS_REGISTRY
    unset MIRROR_NODEJS_DISTURL
    unset MIRROR_NODEJS_SASS_BINARY_SITE
    unset MIRROR_NODEJS_ELECTRON_MIRROR
    unset MIRROR_NODEJS_PUPPETEER_DOWNLOAD_BASE_URL
    unset MIRROR_NODEJS_CHROMEDRIVER_CDNURL
    unset MIRROR_NODEJS_OPERADRIVER_CDNURL
    unset MIRROR_NODEJS_PHANTOMJS_CDNURL
    unset MIRROR_NODEJS_SELENIUM_CDNURL
    unset MIRROR_NODEJS_NODE_INSPECTOR_CDNURL
    unset NVM_NODEJS_ORG_MIRROR
    unset NVS_NODEJS_ORG_MIRROR
    if [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/nodejs/npm_config.sh" ]]; then
        "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/nodejs/npm_config.sh" RESET
    fi
}
