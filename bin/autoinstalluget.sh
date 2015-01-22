#!/bin/bash
# UTUTO-Get autoupgrade tool - shell script
#
# Autor: Pablo Manuel Rizzo <info@pablorizzo.com>
#
# Copyright (C) 2006 The UTUTO Project
# Distributed under the terms of the GNU General Public License v3 or newer
#
# $Header: $


##############################################################################
# Default configuration settings
CONF="/etc/uget/ututo-get.conf"
GET_PROGRAM="wget"
GET_OPTIONS=""
UTUTOGET_URL="http://ututo.conmutador.net/svn.ututo.org/ututo-src/ututo-get/tags/actual"
BEEP="\a"
WHITE="\033[1m"
NO_COLOR="\033[0m"
UGETDIR=/usr/libexec/uget
CONFIGDIR=/etc/uget
REPOSDIR=/var/db/uget
LOGSDIR=/var/log/uget
TMPDIR=/tmp/autoupgradeuget
VERSDIR=$CONFIGDIR/version

##############################################################################
# Load configuration settings
if [ -e "$CONF" ];then
	. $CONF
elif [ -e /etc/ututo-get/ututo-get.conf ]; then
	. /etc/ututo-get/ututo-get.conf
fi

declare forzado=0
if [ "$1" = "-f" -o "$1" = "--force" ]; then
	forzado="1"
	rm -f $CONFIGDIR/*lastupdate*
fi

declare GET="$GET_PROGRAM $GET_OPTIONS"
declare ARCHIVOCTUALIZADO=""

function salvarConfig {
	
	#set -x
	local variables="UGET_LANG GET_PROGRAM PROCESSOR PROTOCOL SERVER NICELEVEL TOUT PRELINK DEBUG REPOSITORIO PORTAGE_URL PORTAGE_FILE"
	for var in $variables
	do
		valor="${!var}"
		[[ "x$valor" != "x" ]] && sed -r -i "/^$var=/s/(\"*)(.*)/$var=\"${valor//\//\\/}\"/" $CONF
	done
	#set +x
	
	[[ "x$GET_PROGRAM" != "x$GET_PROGRAM_PKG" ]] && sed -r -i "/^GET_PROGRAM_PKG=/s/(\"*)(.*)/GET_PROGRAM_PKG=\"${GET_PROGRAM_PKG//\//\\/}\"/" $CONF
	
	[[ "x$http_proxy" != "x" ]] && echo 'export http_proxy="'$http_proxy'"' >> $CONF
	[[ "x$https_proxy" != "x" ]] && echo 'export https_proxy="'$https_proxy'"' >> $CONF
	[[ "x$ftp_proxy" != "x" ]] && echo 'export ftp_proxy="'$ftp_proxy'"' >> $CONF
}

function preconfigututogetsh {
	rm -f /usr/sbin/ututo-get*
	rm -f /usr/bin/ututo-get*
	rm -f /usr/sbin/uget*
	rm -f /usr/bin/uget*
	rm -f $(which ututo-get)
	rm -f $(which uget)
}
function postconfigututogetsh {
	chmod a+x $2/$1
	ln -s $2/$1 /usr/sbin/ututo-get
	ln -s $2/$1 /usr/sbin/uget
}
function preconfigututogetconf {
	BACKUPCONF="$2/$1-$(date +%F-%T)"
	[ ! -d $2 ] && mkdir $2
	if [ -f /etc/ututo-get/ututo-get.conf ]; then
		mv -f /etc/ututo-get/ututo-get.conf $BACKUPCONF
	else
		mv -f $2/$1 $BACKUPCONF
	fi
}
function postconfigututogetconf {
	if [ "$forzado" != "-f" -a "$forzado" != "--force" ]; then
		salvarConfig
	fi
}
function postconfigselectcputypesh {
	ln -s $2/$1 /usr/bin/$1
}
function preconfigcheckldd {
	rm -f $(which check-ldd)
	rm -f /usr/bin/check-ldd
	rm -f /usr/sbin/check-ldd
}
function postconfigautoupdateetcsh {
	ln -s $2/$1 /usr/sbin/auto-update-etc.sh
}
function postconfigcheckldd {
	ln -s $2/$1 /usr/sbin/check-ldd
}

function instalarArchivo {
	local origen=$1
	local archivo=${origen/*\//}
	local destino=$2
	local funcion=$3
	local permisos=$4

	##########################################################
	# Verifica si es necesario actualizar $archivo
	cd $VERSDIR
	$GET -q $UTUTOGET_URL/$origen.lastversion > /dev/null
	[ ! -f $archivo.lastversion ] && echo "1" > $archivo.lastversion 
	local LASTVERSION="`head -n 1 $VERSDIR/$archivo.lastversion`"
	echo -e "Last version of $archivo:$WHITE $LASTVERSION $NO_COLOUR"
	local LASTUPDATE="`head -n 1 $VERSDIR/$archivo.lastupdate`"
	echo -e "Your version of $archivo:$WHITE $LASTUPDATE $NO_COLOUR\n"
	if [ "x$LASTVERSION" != "x$LASTUPDATE" ]; then
	
		cd $TMPDIR
		rm -rf $archivo
		$GET --quiet $UTUTOGET_URL/$origen
		
		mkdir -p $destino
		pre$funcion $1 $2
		while [ -x "$(which $archivo)" ]; do 
			rm -f $(which $archivo) 2>/dev/null
		done
		install -D -m $permisos $TMPDIR/$archivo $destino/$archivo
		post$funcion $1 $2
		
		cp -f $VERSDIR/$archivo.lastversion $VERSDIR/$archivo.lastupdate
	
		ARCHIVOCTUALIZADO="${ARCHIVOCTUALIZADO}$archivo was upgraded to version ${WHITE}0.x.${LASTVERSION/ /}$NO_COLOUR\n"
	
	fi
	echo

}

echo -e "Upgrading ututo-get in 5 seconds\nCtrl-c to cancel..."
for i in 1 2 3 4 5; do
	echo -en "$BEEP$i "; sleep 1s;
done
echo

rm -rf $TMPDIR
mkdir -p $TMPDIR
cd $TMPDIR

mkdir -p $CONFIGDIR
mkdir -p $VERSDIR
rm $VERSDIR/*.lastversion
cd $VERSDIR
$GET -q $UTUTOGET_URL/ututo-get.lastversion > /dev/null

instalarArchivo "ututo-get.sh" "$UGETDIR/bin" "configututogetsh" "554"
instalarArchivo "ututo-get.conf" "$CONFIGDIR" "configututogetconf" "444"
instalarArchivo "lang/ututo-get.es.msg" "$UGETDIR/lang" "configututogeteslang" "444"
instalarArchivo "lang/ututo-get.en.msg" "$UGETDIR/lang" "configututogetenlang" "444"
instalarArchivo "gui/ututo-get-gui.kmdr" "$UGETDIR/bin" "configututogetguikmdr" "555"
instalarArchivo "gui/ututo-get-gui.desktop" "/usr/share/applications" "configututogetguidesktop" "555"
instalarArchivo "gui/ututo-get-gui.png" "$UGETDIR/share/icons" "configututogetgui-png" "444"
instalarArchivo "select_cpu-type.sh" "$UGETDIR/bin" "configselectcputypesh" "555"
instalarArchivo "auto-update-etc.sh" "$UGETDIR/bin" "configautoupdateetcsh" "554"
instalarArchivo "check-ldd" "$UGETDIR/bin" "configcheckldd" "554"


sed -i "/^complete .* uget$/d" /etc/profile
echo "complete -W \"install fixdepend fastinstall fastreinstall reinstall download remove update autoupgradeuget autoupgradesystem\" uget" >> /etc/profile

cp -f $VERSDIR/ututo-get.lastversion $VERSDIR/ututo-get.lastupdate

 
echo -e $ARCHIVOCTUALIZADO

echo -e "Done! $BEEP"
exit;exit;exit;
