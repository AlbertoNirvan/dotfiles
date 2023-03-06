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

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options
[[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && Get_Installer_AXEL_Options

[[ -z "${OS_INFO_DESKTOP}" ]] && get_os_desktop

# Fonts & Input Methods for CJK locale
# https://wiki.archlinux.org/title/Localization/Chinese
# default locale settings: /etc/locale.conf

# Use en_US.UTF-8 for terminal
# https://blog.flowblok.id.au/2013-02/shell-startup-scripts.html
if ! grep -q "^export LANG=" "$HOME/.bashrc" 2>/dev/null; then
    tee -a "$HOME/.bashrc" >/dev/null <<-'EOF'

# locale for terminal
export LANG="en_US.UTF-8"
export LANGUAGE="en_US.UTF-8"
# export LC_ALL="en_US.UTF-8"
EOF
fi

if ! grep -q "^export LANG=" "$HOME/.zshrc" 2>/dev/null; then
    tee -a "$HOME/.zshrc" >/dev/null <<-'EOF'

# locale for terminal
export LANG="en_US.UTF-8"
export LANGUAGE="en_US.UTF-8"
# export LC_ALL="en_US.UTF-8"
EOF
fi

# [Fonts](https://wiki.archlinux.org/title/fonts)
colorEcho "${BLUE}Installing ${FUCHSIA}fonts${BLUE}..."
if [[ -z "${FontManjaroInstallList[*]}" ]]; then
    FontManjaroInstallList=(
        "powerline-fonts"
        "ttf-fira-code"
        # "ttf-font-awesome"
        "ttf-sarasa-gothic"
        "ttf-hannom"
        "noto-fonts"
        "noto-fonts-extra"
        "noto-fonts-cjk"
        "ttf-nerd-fonts-symbols"
        "ttf-iosevka-term"
        "ttf-jetbrains-mono"
        "nerd-fonts-jetbrains-mono"
        "ttf-lxgw-wenkai"
        "ttf-lato"
        "ttf-lora-cyrillic"
        "ttf-playfair-display"
        ## math
        "otf-latin-modern"
        "otf-cm-unicode"
        "otf-stix"
        ## emoji
        "archlinuxcn/ttf-twemoji"
        # "noto-fonts-emoji"
        # "unicode-emoji"
        ## Adobe fonts
        # "adobe-source-code-pro-fonts"
        # "adobe-source-sans-fonts"
        # "adobe-source-serif-fonts"
        # "adobe-source-han-sans-cn-fonts"
        # "adobe-source-han-sans-hk-fonts"
        # "adobe-source-han-sans-tw-fonts"
        # "adobe-source-han-serif-cn-fonts"
        ## WQY
        # "wqy-zenhei"
        # "wqy-microhei"
        ## Windows fonts
        # "ttf-ms-win11-auto"
        ## Other fonts
        # "ttf-dejavu"
        # "ttf-droid"
        # "ttf-hack"
        # "ttf-lato"
        # "ttf-liberation"
        # "ttf-linux-libertine"
        # "ttf-opensans"
        # "ttf-roboto"
        # "ttf-ubuntu-font-family"
    )
fi
for TargetFont in "${FontManjaroInstallList[@]}"; do
    colorEcho "${BLUE}Installing ${FUCHSIA}${TargetFont}${BLUE}..."
    yay --noconfirm --needed -S "${TargetFont}"
done

# emoji
# If you have other emoji fonts installed but want twemoji to always be used, make a symlink for twemojis font config:
# sudo ln -sf /usr/share/fontconfig/conf.avail/75-twemoji.conf /etc/fonts/conf.d/75-twemoji.conf
# You do not need to do this if you are fine with some apps using a different emoji font.
# If you do use other emoji fonts, copy 75-twemoji.conf to /etc/fonts/conf.d/ and remove corresponding aliases.
# To prevent conflicts with other emoji fonts, 75-twemoji.conf is not being automatically installed in /etc/fonts/conf.d/

# [Font Manager](https://github.com/FontManager/font-manager)
colorEcho "${BLUE}Installing ${FUCHSIA}Font Manager${BLUE}..."
sudo pacman --noconfirm --needed -S font-manager

# FiraCode Nerd Font Complete Mono
colorEcho "${BLUE}Installing ${FUCHSIA}FiraCode Nerd Font Complete Mono${BLUE}..."
NerdFont_URL="https://github.com/epoweripione/fonts/releases/download/v0.1.0/FiraCode-Mono-6.2.0.zip"
mkdir -p "${WORKDIR}/FiraCode-Mono" && \
    curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${WORKDIR}/FiraCode-Mono.zip" "${NerdFont_URL}" && \
    unzip -q "${WORKDIR}/FiraCode-Mono.zip" -d "${WORKDIR}/FiraCode-Mono" && \
    sudo mv -f "${WORKDIR}/FiraCode-Mono/" "/usr/share/fonts/" && \
    sudo chmod -R 744 "/usr/share/fonts/FiraCode-Mono"
# fc-list | grep "FiraCode" | column -t -s ":"

# CJK fontconfig & colour emoji
# https://wiki.archlinux.org/title/Localization_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)/Simplified_Chinese_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)
colorEcho "${BLUE}Setting ${FUCHSIA}CJK fontconfig & colour emoji${BLUE}..."
SYSTEM_LOCALE=$(localectl status | grep 'LANG=' | cut -d= -f2 | cut -d. -f1)
# if [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/cjk/fontconfig_alias_${SYSTEM_LOCALE}.xml" ]]; then
#     sudo cp "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/cjk/fontconfig_alias_${SYSTEM_LOCALE}.xml" "/etc/fonts/local.conf"
# fi

## [用 fontconfig 治理 Linux 中的字体](https://catcat.cc/post/2021-03-07/)
## [Linux 下的字体调校指南](https://szclsya.me/zh-cn/posts/fonts/linux-config-guide/)
## [Font configuration/Examples](https://wiki.archlinux.org/title/Font_configuration/Examples)
## [Having multiple values in <test>](https://bbs.archlinuxcn.org/viewtopic.php?id=2736)
# fc-match -s | less
# fc-match sans-serif; fc-match serif; fc-match monospace
# fc-match mono-9:lang=zh-CN
if [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/cjk/fontconfig_${SYSTEM_LOCALE}.xml" ]]; then
    # sudo cp "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/cjk/fontconfig_${SYSTEM_LOCALE}.xml" "/etc/fonts/local.conf"
    mkdir -p "$HOME/.config/fontconfig/"
    cp "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/cjk/fontconfig_${SYSTEM_LOCALE}.xml" "$HOME/.config/fontconfig/fonts.conf"
fi

# update font cache
colorEcho "${BLUE}Updating ${FUCHSIA}fontconfig cache${BLUE}..."
sudo fc-cache -fv

# Fcitx5 input methods for Chinese Pinyin
# https://github.com/fcitx/fcitx5
# https://blog.rasphino.cn/archive/a-taste-of-fcitx5-in-arch.html
colorEcho "${BLUE}Installing ${FUCHSIA}fcitx5 input methods${BLUE}..."
sudo pacman --noconfirm -Rs "$(pacman -Qsq fcitx)"
sudo pacman --noconfirm --needed -S fcitx5-im && \
    sudo pacman --noconfirm --needed -S fcitx5-material-color fcitx5-chinese-addons && \
    sudo pacman --noconfirm --needed -S fcitx5-pinyin-zhwiki fcitx5-pinyin-moegirl

# fcitx5-chinese-addons: 简体中文 | Simplified Chinese
# fcitx5-rime: 繁體中文 | Traditional Chinese
# fcitx5-mozc: 日本語 | Japanese
# fcitx5-anthy: 日本語 | Japanese
# fcitx5-hangul: 한국어 | Korean
# fcitx5-unikey: Tiếng Việt | Vietnamese
# fcitx5-m17n: other languages provided by M17n(http://www.nongnu.org/m17n/)
sudo pacman --noconfirm --needed -S fcitx5-m17n 

if ! grep -q "^GTK_IM_MODULE" "$HOME/.pam_environment" 2>/dev/null; then
    tee -a "$HOME/.pam_environment" >/dev/null <<-'EOF'
# fcitx5
INPUT_METHOD DEFAULT=fcitx5
GTK_IM_MODULE DEFAULT=fcitx5
QT_IM_MODULE  DEFAULT=fcitx5
XMODIFIERS    DEFAULT=\@im=fcitx5
SDL_IM_MODULE DEFAULT=fcitx5
EOF
fi

if ! grep -q "^export GTK_IM_MODULE" "$HOME/.xprofile" 2>/dev/null; then
    tee -a "$HOME/.xprofile" >/dev/null <<-'EOF'
# fcitx5
export INPUT_METHOD DEFAULT=fcitx5
export GTK_IM_MODULE=fcitx5
export QT_IM_MODULE=fcitx5
export XMODIFIERS="@im=fcitx5"
export SDL_IM_MODULE=fcitx5

# auto start fcitx5
fcitx5 &
EOF
fi

# Rime
# https://github.com/rime/home/wiki/UserGuide
# rime-cloverpinyin
# https://github.com/fkxxyz/rime-cloverpinyin
# ~/.local/share/fcitx5/rime/
colorEcho "${BLUE}Installing ${FUCHSIA}fcitx5 Rime support${BLUE}..."
sudo pacman --noconfirm --needed -S fcitx5-rime rime-cloverpinyin

# Rime Emoji & Symbols
yay --noconfirm --needed -S rime-opencc-emoji-symbols-git

# merge emoji & symbol
# /usr/share/rime-data/opencc/symbol_category.txt
if  [[ -s "/usr/share/rime-data/opencc/symbol_category.txt" && -s "/usr/share/rime-data/opencc/emoji_category.txt" ]]; then
    awk '{print $1}' \
            "/usr/share/rime-data/opencc/emoji_category.txt" \
            "/usr/share/rime-data/opencc/emoji_word.txt" \
        | uniq > "${WORKDIR}/wordlist.txt"

    grep -wvf "${WORKDIR}/wordlist.txt" "/usr/share/rime-data/opencc/symbol_category.txt" \
        | grep -Ev '^\s' \
        | sudo tee -a "/usr/share/rime-data/opencc/emoji_category.txt" >/dev/null
fi

# /usr/share/rime-data/opencc/symbol_word.txt
if  [[ -s "/usr/share/rime-data/opencc/symbol_word.txt" && -s "/usr/share/rime-data/opencc/emoji_word.txt" ]]; then
    awk '{print $1}' \
            "/usr/share/rime-data/opencc/emoji_category.txt" \
            "/usr/share/rime-data/opencc/emoji_word.txt" \
        | uniq > "${WORKDIR}/wordlist.txt"
    
    DUPLICATE_ENTRY=$(awk '{print $1}' "/usr/share/rime-data/opencc/symbol_word.txt" | sort | uniq -cd | awk '{print $2}')
    while read -r DUPLICATE_WORD; do
        [[ -z "${DUPLICATE_WORD}" ]] && continue
        sudo sed -i "0,/${DUPLICATE_WORD}/b; /${DUPLICATE_WORD}/d" "/usr/share/rime-data/opencc/symbol_word.txt"
    done <<<"${DUPLICATE_ENTRY}"

    grep -wvf "${WORKDIR}/wordlist.txt" "/usr/share/rime-data/opencc/symbol_word.txt" \
        | grep -Ev '^\s' \
        | sudo tee -a "/usr/share/rime-data/opencc/emoji_word.txt" >/dev/null
fi

# /usr/share/rime-data/opencc/es.txt
if  [[ -s "/usr/share/rime-data/opencc/es.txt" && -s "/usr/share/rime-data/opencc/emoji_word.txt" ]]; then
    awk '{print $1}' \
            "/usr/share/rime-data/opencc/emoji_category.txt" \
            "/usr/share/rime-data/opencc/emoji_word.txt" \
        | uniq > "${WORKDIR}/wordlist.txt"
    
    DUPLICATE_ENTRY=$(awk '{print $1}' "/usr/share/rime-data/opencc/es.txt" | sort | uniq -cd | awk '{print $2}')
    while read -r DUPLICATE_WORD; do
        [[ -z "${DUPLICATE_WORD}" ]] && continue
        sudo sed -i "0,/${DUPLICATE_WORD}/b; /${DUPLICATE_WORD}/d" "/usr/share/rime-data/opencc/es.txt"
    done <<<"${DUPLICATE_ENTRY}"

    grep -wvf "${WORKDIR}/wordlist.txt" "/usr/share/rime-data/opencc/es.txt" \
        | grep -Ev '^\s' \
        | sudo tee -a "/usr/share/rime-data/opencc/emoji_word.txt" >/dev/null
fi

mkdir -p "$HOME/.local/share/fcitx5/rime/"
# setting rime-cloverpinyin
tee "$HOME/.local/share/fcitx5/rime/default.custom.yaml" >/dev/null <<-'EOF'
patch:
  "menu/page_size": 9
  schema_list:
    - schema: clover
EOF

# https://github.com/fkxxyz/rime-cloverpinyin/wiki/issues
tee "$HOME/.local/share/fcitx5/rime/clover.custom.yaml" >/dev/null <<-'EOF'
patch:
  speller/algebra:
    # 模糊音定义
    # 需要哪组就删去行首的 # 号，单双向任选
    #- derive/^([zcs])h/$1/             # zh, ch, sh => z, c, s
    - derive/^([zcs])([^h])/$1h$2/     # z, c, s => zh, ch, sh

    #- derive/^n/l/                     # n => l
    #- derive/^l/n/                     # l => n

    # 这两组一般是单向的
    #- derive/^r/l/                     # r => l

    #- derive/^ren/yin/                 # ren => yin, reng => ying
    #- derive/^r/y/                     # r => y

    # 下面 hu <=> f 这组写法复杂一些，分情况讨论
    #- derive/^hu$/fu/                  # hu => fu
    #- derive/^hong$/feng/              # hong => feng
    #- derive/^hu([in])$/fe$1/          # hui => fei, hun => fen
    #- derive/^hu([ao])/f$1/            # hua => fa, ...

    #- derive/^fu$/hu/                  # fu => hu
    #- derive/^feng$/hong/              # feng => hong
    #- derive/^fe([in])$/hu$1/          # fei => hui, fen => hun
    #- derive/^f([ao])/hu$1/            # fa => hua, ...

    # 韵母部份
    #- derive/^([bpmf])eng$/$1ong/      # meng = mong, ...
    #- derive/([ei])n$/$1ng/            # en => eng, in => ing
    #- derive/([ei])ng$/$1n/            # eng => en, ing => in

    # 反模糊音？
    # 谁说方言没有普通话精确、有模糊音，就能有反模糊音。
    # 示例为分尖团的中原官话：
    #- derive/^ji$/zii/   # 在设计者安排下鸠占鹊巢，尖音 i 只好双写了
    #- derive/^qi$/cii/
    #- derive/^xi$/sii/
    #- derive/^ji/zi/
    #- derive/^qi/ci/
    #- derive/^xi/si/
    #- derive/^ju/zv/
    #- derive/^qu/cv/
    #- derive/^xu/sv/

    # 韵母部份，只能从大面上覆盖
    #- derive/^([bpm])o$/$1eh/          # bo => beh, ...
    #- derive/(^|[dtnlgkhzcs]h?)e$/$1eh/  # ge => geh, se => sheh, ...
    #- derive/^([gkh])uo$/$1ue/         # guo => gue, ...
    #- derive/^([gkh])e$/$1uo/          # he => huo, ...
    #- derive/([uv])e$/$1o/             # jue => juo, lve => lvo, ...
    #- derive/^fei$/fi/                 # fei => fi
    #- derive/^wei$/vi/                 # wei => vi
    #- derive/^([nl])ei$/$1ui/          # nei => nui, lei => lui
    #- derive/^([nlzcs])un$/$1vn/       # lun => lvn, zun => zvn, ... 
    #- derive/^([nlzcs])ong$/$1iong/    # long => liong, song => siong, ...
    # 这个办法虽从拼写上做出了区分，然而受词典制约，候选字仍是混的。
    # 只有真正的方音输入方案才能做到！但「反模糊音」这个玩法快速而有效！

    # 模糊音定义先于简拼定义，方可令简拼支持以上模糊音
    - abbrev/^([a-z]).+$/$1/           # 簡拼（首字母）
    - abbrev/^([zcs]h).+$/$1/          # 簡拼（zh, ch, sh）

    # 以下是一组容错拼写，《汉语拼音》方案以前者为正
    - derive/^([nl])ve$/$1ue/          # nve = nue, lve = lue
    - derive/^([jqxy])u/$1v/           # ju = jv,
    - derive/un$/uen/                  # gun = guen,
    - derive/ui$/uei/                  # gui = guei,
    - derive/iu$/iou/                  # jiu = jiou,

    # 自动纠正一些常见的按键错误
    - derive/([aeiou])ng$/$1gn/        # dagn => dang 
    - derive/([dtngkhrzcs])o(u|ng)$/$1o/  # zho => zhong|zhou
    - derive/ong$/on/                  # zhonguo => zhong guo
    - derive/ao$/oa/                   # hoa => hao
    - derive/([iu])a(o|ng?)$/a$1$2/    # tain => tian

#   switches:
#     - name: zh_simp_s2t
#       reset: 0
#       states: [ 简, 繁 ]
#     - name: emoji_suggestion
#       reset: 1
#       states: [ "🈚️️\uFE0E", "🈶️️\uFE0F" ]
#     - name: symbol_support
#       reset: 1
#       states: [ "无符", "符" ]
#     - name: ascii_punct
#       reset: 0
#       states: [ 。，, ．， ]
#     - name: full_shape
#       reset: 0
#       states: [ 半, 全 ]
#     - name: ascii_mode
#       reset: 0
#       states: [ 中, 英 ]
#     - name: show_es
#       reset: 1
#       states: [ 😔, 😀 ]

#   engine:
#     filters:
#       - simplifier@es_conversion

#   es_conversion:
#     opencc_config: es.json
#     option_name: show_es

#   "switches/@5/reset": 1
EOF


# fcitx5 theme
# https://github.com/hosxy/Fcitx5-Material-Color
mkdir -p "$HOME/.config/fcitx5/conf"
if ! grep -q "^Vertical Candidate List" "$HOME/.config/fcitx5/conf/classicui.conf" 2>/dev/null; then
    tee -a "$HOME/.config/fcitx5/conf/classicui.conf" >/dev/null <<-'EOF'
Vertical Candidate List=False
PerScreenDPI=True
Font="更纱黑体 SC Medium 13"

Theme=Material-Color-Blue
EOF
fi

# emoji emoticons
# https://github.com/levinit/fcitx-emoji
if [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/manjaro/QuickPhrase.mb" ]]; then
    mkdir -p "$HOME/.local/share/fcitx5/data/"
    cat "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/manjaro/QuickPhrase.mb" >> "$HOME/.local/share/fcitx5/data/QuickPhrase.mb"
fi


## How to Insert Emojis & Special Characters
## [Unicode Character Code Charts](http://unicode.org/charts/)
## [Linux keyboard shortcuts for text symbols](https://fsymbols.com/keyboard/linux/)
## Linux keyboard: Unicode hex codes composition
# Hold down `Ctrl+Shift+U` keys (at the same time).
# Release the keys.
# Enter Unicode symbol's hex code.
# Enter hexadecimal (base 16 - 0123456789abcdef) code of symbol you want to type.
# For example try 266A to get ♪. Or 1F44F for 👏
# Press [Space] key

## KDE: [krunner-symbols](https://github.com/domschrei/krunner-symbols)
##      [KCharSelect](https://utils.kde.org/projects/kcharselect/)
if [[ "${OS_INFO_DESKTOP}" == "KDE" ]]; then
    colorEcho "${BLUE}Installing ${FUCHSIA}KCharSelect${BLUE}..."
    sudo pacman --noconfirm --needed -S kcharselect

    colorEcho "${BLUE}Installing ${FUCHSIA}krunner-symbols${BLUE}..."
    sudo pacman --noconfirm --needed -S ki18n krunner qt5-base cmake extra-cmake-modules

    mkdir -p "$HOME/Applications"
    Git_Clone_Update_Branch "domschrei/krunner-symbols" "$HOME/Applications/krunner-symbols"
    [[ -d "$HOME/Applications/krunner-symbols" ]] && cd "$HOME/Applications/krunner-symbols" && bash build_and_install.sh
fi

## GNOME: Insert Special Characters via `GNOME Characters` App
# GNOME Characters
if [[ "${OS_INFO_DESKTOP}" == "GNOME" ]]; then
    colorEcho "${BLUE}Installing ${FUCHSIA}GNOME Characters${BLUE}..."
    sudo pacman --noconfirm --needed -S gnome-characters

    if [[ -x "$(command -v snap)" && ! -x "$(command -v gnome-characters)" ]]; then
        sudo snap install gnome-characters
    fi
fi

## Emoji keyboard
## https://github.com/OzymandiasTheGreat/emoji-keyboard
# GITHUB_REPO_NAME="OzymandiasTheGreat/emoji-keyboard"
# DOWNLOAD_FILENAME="$HOME/Applications/emoji-keyboard.AppImage"
# CHECK_URL="https://api.github.com/repos/${GITHUB_REPO_NAME}/releases/latest"
# App_Installer_Get_Remote_Version "${CHECK_URL}"
# DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/${GITHUB_REPO_NAME}/releases/download/${REMOTE_VERSION}/emoji-keyboard-${REMOTE_VERSION}.AppImage"
# colorEcho "${BLUE}Installing ${FUCHSIA}${APP_INSTALL_NAME} ${YELLOW}${REMOTE_VERSION}${BLUE}..."
# colorEcho "${BLUE}  From ${ORANGE}${DOWNLOAD_URL}"
# curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"
colorEcho "${BLUE}Installing ${FUCHSIA}Emoji keyboard${BLUE}..."
yay --noconfirm --needed -S aur/emoji-keyboard

# [Emote](https://github.com/tom-james-watson/Emote): Modern popup emoji picker
# Launch the emoji picker with the configurable keyboard shortcut `Ctrl+Alt+E` 
# and select one or more emojis to paste them into the currently focussed app.
colorEcho "${BLUE}Installing ${FUCHSIA}emote${BLUE}..."
yay --noconfirm --needed -S aur/emote

if [[ -x "$(command -v snap)" && ! -x "$(command -v emote)" ]]; then
    sudo snap install emote
fi

# add to autostart
if [[ -x "$(command -v emote)" ]]; then
    tee "$HOME/.config/autostart/emote.desktop" >/dev/null <<-'EOF'
[Desktop Entry]
Encoding=UTF-8
Type=Application
Name=emote
Icon=emote-love
Comment=Modern popup emoji picker
Exec=/usr/bin/python3 "$(which emote)"
StartupNotify=false
Terminal=false
Hidden=false
EOF
fi

# [Onboard Onscreen Keyboard](https://launchpad.net/onboard)
sudo pacman --noconfirm --needed -S onboard

# SDDM: Virtual Keyboard on Login screen
if [[ -s "/etc/sddm.conf" ]]; then
    sudo sed -i 's|^InputMethod=.*|InputMethod=qtvirtualkeyboard|' "/etc/sddm.conf"
fi

## Pinyin shortcut
# Ctrl+Alt+Shift+u: Unicode encoding & emoji & special characters
# Ctrl+.: switch between symbols ASCII Punctuation and Chinese Punctuation Marks
# ; v: QuickPhrase

## rime-cloverpinyin shortcut
# Ctrl+Shift+2 Ctrl+Shift+f: switch between Traditional Chinese and Simplified Chinese
# Ctrl+Shift+3: emoji
# Ctrl+Shift+4: special characters
# Ctrl+Shift+5 Ctrl+, Ctrl+.: switch between symbols ASCII Punctuation and Chinese Punctuation Marks
# Ctrl+Shift+6 Shift+Space: switch between halfwidth and fullwidth punctuation

## 快速输入带声调的汉语拼音
# 切换至 拼音符号(M17N) 输入法，然后用 拼音 + 数字1234


cd "${CURRENT_DIR}" || exit
