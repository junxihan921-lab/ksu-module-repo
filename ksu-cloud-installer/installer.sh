#!/system/bin/sh

MODDIR=${0%/*}

REPO_URL="https://raw.githubusercontent.com/junxihan921-lab/ksu-module-repo/main/modules.json"
LOG="$MODDIR/install.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG"
}

log "================================"
log "KSU Cloud Installer started"
log "================================"

# 检查下载工具
if command -v curl >/dev/null 2>&1; then
    DOWNLOAD="curl -L --fail --silent --show-error"
elif command -v wget >/dev/null 2>&1; then
    DOWNLOAD="wget -q -O -"
else
    log "ERROR: curl/wget 不存在"
    exit 1
fi

TMP="$MODDIR/modules.json"

log "下载云端模块列表..."

if ! $DOWNLOAD "$REPO_URL" > "$TMP"; then
    log "ERROR: modules.json 下载失败"
    exit 1
fi

if [ ! -s "$TMP" ]; then
    log "ERROR: modules.json 为空"
    exit 1
fi

log "modules.json 下载成功"

# 检查 jq
if ! command -v jq >/dev/null 2>&1; then
    log "ERROR: jq 不存在"
    exit 1
fi

COUNT=$(jq '.modules | length' "$TMP" 2>/dev/null)

if [ -z "$COUNT" ] || [ "$COUNT" = "null" ]; then
    log "ERROR: modules.json 格式错误"
    exit 1
fi

log "发现 $COUNT 个云端模块"

i=0

while [ "$i" -lt "$COUNT" ]; do

    ID=$(jq -r ".modules[$i].id" "$TMP")
    NAME=$(jq -r ".modules[$i].name" "$TMP")
    URL=$(jq -r ".modules[$i].url" "$TMP")

    log "--------------------------------"
    log "模块: $NAME"
    log "ID: $ID"
    log "URL: $URL"

    ZIP="$MODDIR/${ID}.zip"

    log "开始下载..."

    if $DOWNLOAD "$URL" > "$ZIP"; then
        log "下载成功: $ZIP"
    else
        log "下载失败: $NAME"
        rm -f "$ZIP"
        i=$((i + 1))
        continue
    fi

    if [ ! -s "$ZIP" ]; then
        log "ERROR: ZIP 文件为空"
        rm -f "$ZIP"
        i=$((i + 1))
        continue
    fi

    # 使用 KernelSU 官方命令安装模块
    if command -v ksud >/dev/null 2>&1; then

        log "调用 ksud 安装模块..."

        if ksud module install "$ZIP" >> "$LOG" 2>&1; then
            log "模块安装成功: $NAME"
        else
            log "模块安装失败: $NAME"
        fi

    else
        log "ERROR: ksud 不存在"
    fi

    rm -f "$ZIP"

    i=$((i + 1))
done

rm -f "$TMP"

log "================================"
log "KSU Cloud Installer finished"
log "================================"

exit 0
