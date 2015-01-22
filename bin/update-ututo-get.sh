#!/bin/bash
# UTUTO-Get server-side autoupgrade tool - shell script
#
# Autor: Pablo Manuel Rizzo <info@pablorizzo.com>
#
# Copyright (C) 2006 The UTUTO Project
# Distributed under the terms of the GNU General Public License v3 or newer
#
# $Header: $

directorio=`dirname $0`
cd $directorio
svn cleanup
sleep 1
svn update
svn info ututo-get.sh | grep "Last Changed Rev: " | cut -d : -f 2 > ututo-get.sh.lastversion
svn info ututo-get.conf | grep "Last Changed Rev: " | cut -d : -f 2 > ututo-get.conf.lastversion
svn info select_cpu-type.sh | grep "Last Changed Rev: " | cut -d : -f 2 > select_cpu-type.sh.lastversion
svn info auto-update-etc.sh | grep "Last Changed Rev: " | cut -d : -f 2 > auto-update-etc.sh.lastversion
svn info check-ldd | grep "Last Changed Rev: " | cut -d : -f 2 > check-ldd.lastversion

svn info lang/ututo-get.en.msg | grep "Last Changed Rev: " | cut -d : -f 2 > lang/ututo-get.en.msg.lastversion
svn info lang/ututo-get.es.msg | grep "Last Changed Rev: " | cut -d : -f 2 > lang/ututo-get.es.msg.lastversion

svn info gui/ututo-get-gui.desktop | grep "Last Changed Rev: " | cut -d : -f 2 > gui/ututo-get-gui.desktop.lastversion
svn info gui/ututo-get-gui.kmdr | grep "Last Changed Rev: " | cut -d : -f 2 > gui/ututo-get-gui.kmdr.lastversion
svn info gui/ututo-get-gui.png | grep "Last Changed Rev: " | cut -d : -f 2 > gui/ututo-get-gui.png.lastversion

VER="$(echo -n `cat ututo-get.sh.lastversion`)"
VER="$VER $(echo -n `cat ututo-get.conf.lastversion`)"
VER="$VER $(echo -n `cat select_cpu-type.sh.lastversion`)"
VER="$VER $(echo -n `cat auto-update-etc.sh.lastversion`)"
VER="$VER $(echo -n `cat check-ldd.lastversion`)"

VER="$VER $(echo -n `cat lang/ututo-get.en.msg.lastversion`)"
VER="$VER $(echo -n `cat lang/ututo-get.es.msg.lastversion`)"

VER="$VER $(echo -n `cat gui/ututo-get-gui.desktop.lastversion`)"
VER="$VER $(echo -n `cat gui/ututo-get-gui.kmdr.lastversion`)"
VER="$VER $(echo -n `cat gui/ututo-get-gui.png.lastversion`)"

echo $VER > ututo-get.lastversion
