#!/system/bin/sh

MODDIR=${0%/*}

echo "================================"
echo " KSU Cloud Installer"
echo " 开始检查云端模块..."
echo "================================"

if [ -x "$MODDIR/installer.sh" ]; then
    "$MODDIR/installer.sh"
else
    echo "错误：installer.sh 不存在或不可执行"
    exit 1
fi

echo ""
echo "云端模块检查完成"
