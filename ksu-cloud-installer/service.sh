#!/system/bin/sh

MODDIR=${0%/*}

# 等待 Android 系统基本启动完成
(
    sleep 30

    # 执行云端模块检查
    if [ -x "$MODDIR/installer.sh" ]; then
        "$MODDIR/installer.sh" >> "$MODDIR/install.log" 2>&1
    fi
) &
