#!/system/bin/sh

ui_print "================================"
ui_print "   KSU Cloud Installer"
ui_print "   云端模块自动安装器"
ui_print "================================"
ui_print ""
ui_print "正在安装主模块..."
ui_print ""

# 当前模块安装目录
MODDIR="$MODPATH"

# 设置权限
set_perm "$MODDIR/service.sh" 0 0 0755
set_perm "$MODDIR/action.sh" 0 0 0755
set_perm "$MODDIR/installer.sh" 0 0 0755
set_perm "$MODDIR/bin/cloud-installer.sh" 0 0 0755

ui_print "主模块文件安装完成"
ui_print ""
ui_print "正在连接 GitHub 云端..."

# 首次刷入时立即执行云端安装
if [ -x "$MODDIR/installer.sh" ]; then

    if CHECK_DELAY=0 "$MODDIR/installer.sh"; then
        ui_print ""
        ui_print "云端模块处理完成"
    else
        ui_print ""
        ui_print "云端模块安装出现错误"
        ui_print "主模块仍会正常安装"
        ui_print "可查看 install.log"
    fi

else

    ui_print "错误：installer.sh 不存在"

fi

ui_print ""
ui_print "KSU Cloud Installer 安装完成"
