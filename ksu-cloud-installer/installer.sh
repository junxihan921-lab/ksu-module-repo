#!/system/bin/sh

MODDIR=${0%/*}

CONFIG="$MODDIR/config/config.conf"
LOG="$MODDIR/install.log"
TMP="$MODDIR/modules.json"
CACHE="$MODDIR/cache"

DEFAULT_REPO_URL="https://raw.githubusercontent.com/junxihan921-lab/ksu-module-repo/main/modules.json"

REPO_URL="$DEFAULT_REPO_URL"
AUTO_INSTALL="true"
CHECK_DELAY="0"

mkdir -p "$CACHE"

log() {
    MSG="$*"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $MSG" >> "$LOG"
}

# 读取配置
if [ -f "$CONFIG" ]; then
    while IFS='=' read -r KEY VALUE; do
        case "$KEY" in
            REPO_URL)
                [ -n "$VALUE" ] && REPO_URL="$VALUE"
                ;;
            AUTO_INSTALL)
                [ -n "$VALUE" ] && AUTO_INSTALL="$VALUE"
                ;;
            CHECK_DELAY)
                [ -n "$VALUE" ] && CHECK_DELAY="$VALUE"
                ;;
        esac
    done < "$CONFIG"
fi

log "================================"
log "KSU Cloud Installer"
log "启动云端模块检查"
log "================================"

if [ "$AUTO_INSTALL" != "true" ]; then
    log "AUTO_INSTALL=false，跳过"
    exit 0
fi

if [ "$CHECK_DELAY" -gt 0 ] 2>/dev/null; then
    sleep "$CHECK_DELAY"
fi

# 检查下载工具
DOWNLOAD=""

if command -v curl >/dev/null 2>&1; then
    DOWNLOAD="curl"
elif command -v wget >/dev/null 2>&1; then
    DOWNLOAD="wget"
else
    log "ERROR: curl/wget 均不存在"
    exit 1
fi

log "下载工具: $DOWNLOAD"
log "云端地址: $REPO_URL"

download_file() {
    URL="$1"
    OUT="$2"

    if [ "$DOWNLOAD" = "curl" ]; then
        curl -L \
            --fail \
            --silent \
            --show-error \
            --connect-timeout 15 \
            --max-time 300 \
            -o "$OUT" \
            "$URL"
    else
        wget -q -O "$OUT" "$URL"
    fi
}

# 下载 JSON
rm -f "$TMP"

log "开始下载 modules.json"

if ! download_file "$REPO_URL" "$TMP"; then
    log "ERROR: modules.json 下载失败"
    exit 1
fi

if [ ! -s "$TMP" ]; then
    log "ERROR: modules.json 为空"
    exit 1
fi

log "modules.json 下载成功"

# ------------------------------------------------
# 解析 JSON
#
# 适配这种格式：
#
# {
#   "modules": [
#     {
#       "id": "game_optimizer",
#       "name": "游戏优化助手",
#       "version": "1.0.0",
#       "url": "https://...",
#       "sha256": ""
#     }
#   ]
# }
# ------------------------------------------------

MODULE_LIST="$CACHE/module_list.txt"
rm -f "$MODULE_LIST"

awk '
BEGIN {
    id=""
    name=""
    url=""
}

/"id"[[:space:]]*:/ {
    line=$0
    sub(/^.*"id"[[:space:]]*:[[:space:]]*"/, "", line)
    sub(/".*$/, "", line)
    id=line
}

/"name"[[:space:]]*:/ {
    line=$0
    sub(/^.*"name"[[:space:]]*:[[:space:]]*"/, "", line)
    sub(/".*$/, "", line)
    name=line
}

/"url"[[:space:]]*:/ {
    line=$0
    sub(/^.*"url"[[:space:]]*:[[:space:]]*"/, "", line)
    sub(/".*$/, "", line)
    url=line

    if (id != "" && url != "") {
        print id "|" name "|" url
        id=""
        name=""
        url=""
    }
}
' "$TMP" > "$MODULE_LIST"

if [ ! -s "$MODULE_LIST" ]; then
    log "ERROR: 没有解析到任何云端模块"
    log "请检查 modules.json"
    exit 1
fi

COUNT=0

while IFS='|' read -r ID NAME URL; do

    [ -z "$ID" ] && continue
    [ -z "$URL" ] && continue

    COUNT=$((COUNT + 1))

    log "--------------------------------"
    log "发现模块: $NAME"
    log "ID: $ID"
    log "URL: $URL"

    ZIP="$CACHE/${ID}.zip"

    rm -f "$ZIP"

    log "开始下载模块..."

    if ! download_file "$URL" "$ZIP"; then
        log "ERROR: 模块下载失败: $NAME"
        continue
    fi

    if [ ! -s "$ZIP" ]; then
        log "ERROR: ZIP 文件为空: $NAME"
        rm -f "$ZIP"
        continue
    fi

    log "模块下载成功: $NAME"
    log "ZIP 大小: $(wc -c < "$ZIP") bytes"

    # 检查 ksud
    KSUD=""

    if command -v ksud >/dev/null 2>&1; then
        KSUD="ksud"
    elif [ -x "/data/adb/ksud" ]; then
        KSUD="/data/adb/ksud"
    fi

    if [ -z "$KSUD" ]; then
        log "ERROR: 找不到 ksud"
        continue
    fi

    log "找到 ksud: $KSUD"
    log "开始安装: $NAME"

    "$KSUD" module install "$ZIP" >> "$LOG" 2>&1
    RESULT=$?

    if [ "$RESULT" -eq 0 ]; then
        log "模块安装成功: $NAME"
        rm -f "$ZIP"
    else
        log "ERROR: 模块安装失败: $NAME"
        log "ksud 返回码: $RESULT"
    fi

done < "$MODULE_LIST"

rm -f "$TMP"

log "================================"
log "本次发现模块: $COUNT"
log "KSU Cloud Installer 完成"
log "================================"

exit 0
