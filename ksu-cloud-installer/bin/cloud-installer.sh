#!/system/bin/sh

MODDIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
LOG="$MODDIR/../install.log"

echo "================================" >> "$LOG"
echo "KSU Cloud Installer" >> "$LOG"
echo "开始执行云端安装任务" >> "$LOG"
echo "================================" >> "$LOG"

if [ -x "$MODDIR/../installer.sh" ]; then
    "$MODDIR/../installer.sh" >> "$LOG" 2>&1
    RESULT=$?
else
    echo "ERROR: installer.sh 不存在或不可执行" >> "$LOG"
    RESULT=1
fi

if [ "$RESULT" -eq 0 ]; then
    echo "云端安装任务完成" >> "$LOG"
else
    echo "云端安装任务出现错误，返回码: $RESULT" >> "$LOG"
fi

exit "$RESULT"
