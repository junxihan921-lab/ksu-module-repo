#!/system/bin/sh

ui_print "================================"
ui_print "   KSU Cloud Installer"
ui_print "   云端模块自动安装器"
ui_print "================================"
ui_print ""
ui_print "正在安装主模块..."
ui_print ""

set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/installer.sh" 0 0 0755
set_perm "$MODPATH/bin/cloud-installer.sh" 0 0 0755

ui_print "主模块安装完成"
ui_print ""
ui_print "首次启动后将检查云端模块列表。"
