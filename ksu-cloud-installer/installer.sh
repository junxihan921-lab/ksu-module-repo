#!/system/bin/sh

MODDIR=${0%/*}

CONFIG="$MODDIR/config/config.conf"
LOG="$MODDIR/install.log"
TMP="$MODDIR/modules.json"
CACHE="$MODDIR/cache"

DEFAULT_REPO_URL="https://raw.githubusercontent.com/junxihan921-lab/ksu-module-repo/main/modules.json"
REPO_URL="$DEFAULT_REPO_URL"
AUTO_INSTALL="true"
CHECK_DELAY="30"

mkdir -p "$CACHE"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG"
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
    log "AUTO_INSTALL=false，跳过自动安装"
    exit 0
fi

# 等待网络
if [ -n "$CHECK_DELAY" ] && [ "$CHECK_DELAY" -gt 0 ] 2>/dev/null; then
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

# 下载函数
download_file() {
    URL="$1"
    OUT="$2"

    if [ "$DOWNLOAD" = "curl" ]; then
        curl -L --fail --silent --show-error \
            --connect-timeout 15 \
            --max-time 300 \
            -o "$OUT" "$URL"
    else
        wget -q -O "$OUT" "$URL"
    fi
}

# 下载 modules.json
rm -f "$TMP"

if ! download_file "$REPO_URL" "$TMP"; then
    log "ERROR: modules.json 下载失败"
    exit 1
fi

if [ ! -s "$TMP" ]; then
    log "ERROR: modules.json 为空"
    rm -f "$TMP"
    exit 1
fi

log "modules.json 下载成功"

# 当前云端 JSON 的简单解析
# 每个模块对象一行/连续字段时提取 id/name/url
extract_modules() {
    sed 's/[{}]/\n/g' "$TMP" |
    sed 's/],/]\n/g' |
    grep '"id"' |
    while IFS= read -r LINE; do

        ID=$(echo "$LINE" |
            sed -n 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

        NAME=$(echo "$LINE" |
            sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

        URL=$(echo "$LINE" |
            sed -n 's/.*"url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

        if [ -n "$ID" ] && [ -n "$URL" ]; then
            echo "$ID|$NAME|$URL"
        fi
    done
}

MODULE_LIST="$CACHE/module_list.txt"
rm -f "$MODULE_LIST"

extract_modules > "$MODULE_LIST"

if [ ! -s "$MODULE_LIST" ]; then
    log "ERROR: 没有解析到任何云端模块"
    log "请检查 modules.json 格式"
    rm -f "$TMP"
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
        rm -f "$ZIP"
        continue
    fi

    if [ ! -s "$ZIP" ]; then
        log "ERROR: 下载文件为空: $NAME"
        rm -f "$ZIP"
        continue
    fi

    log "模块下载成功: $NAME"

    # 当前版本先保存下载包
    # 不直接把 ZIP 解压到 /data/adb/modules
    #
    # KernelSU 官方模块本身是 ZIP 安装包，
    # 但官方文档没有确认 ksud module install 作为通用安装接口。
    #
    # 因此这里先完成可靠下载，避免错误调用未知命令。

    FINAL="$CACHE/${ID}.zip"

    if [ -f "$FINAL" ]; then
        log "模块包已保存: $FINAL"
    fi

done < "$MODULE_LIST"

rm -f "$TMP"

log "--------------------------------"
log "云端模块数量: $COUNT"
log "云端检查完成"
log "================================"

exit 0
