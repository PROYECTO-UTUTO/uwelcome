#!/bin/bash
# UTUTO-Get - shell script
#
# Autor: Pablo Manuel Rizzo <info@pablorizzo.com>
#
# Copyright (C) 2006 The UTUTO Project
# Distributed under the terms of the GNU General Public License v3 or newer
#
# $Header: $
#
# set locale
sed -i "s/emerging by path is broken and may not always work/UTUTO XS GNU System Installer - UGet/" /usr/lib/portage/pym/_emerge/main.py
sed -r -i '/emerging by path is broken and may not always work/s/^/#/' /usr/lib/portage/pym/_emerge/__init__.py
sed -i -r 's/display_preserved_libs\([a-z]+\)[^:]/print " " # display_preserved_libs(varslib)/' /usr/lib/portage/pym/_emerge/__init__.py

if [ -e /dist-upgrade.notfound ];then
    clear
    echo " "
    echo " "
    echo " "
    echo " "
    echo " "
    echo "--------------------------------------------------------------------------------------"
    echo "UGET se ha detenido porque existe un error previo reportado en /dist-upgrade.notfound "
    echo "UGET was stoped because exits previos error logfile reported in /dist-upgrade.notfound"
    echo " "
    echo "Verifique el error que fue reportado y/o quite el archivo indicado para relanzar UGET "
    echo "Please check this error previously reported and/or remove this file to restart UGET   "
    echo "--------------------------------------------------------------------------------------"
    exit ; exit ; exit
else
    if [ "x$2" = "x" ];then
	if [ "x$1" = "x" ];then
	    PARAM1=""
	    PARAM2=""
	else
	    PARAM1="$1"
	    PARAM2=""
	fi
    else
	PARAM1="$1"
	PARAM2="$2"
    fi
fi

REPOSITORIO=`cat /etc/uget/ututo-get.conf | grep "REPOSITORIO" | grep -v "#" | grep -v "case" | cut -d "\"" -f 2`
cat /etc/hosts | grep -v "packages.ututo.org" | grep -v "pkg.ututo.org" > /etc/hosts.new
mv /etc/hosts.new /etc/hosts
chown root.root /etc/hosts
chmod 644 /etc/hosts 
mkdir /usr/lib/ccache 2>/dev/null
mkdir /usr/lib/ccache/bin 2>/dev/null

touch /system.name
SYSTEMNAME=`head /system.name -n 1`
if [ "$SYSTEMNAME" = "" ];then
    SYSTEMNAME2="UTUTO XS"
else
    SYSTEMNAME2="$SYSTEMNAME"
fi
LANGLOCALE=`cat /etc/env.d/02locale | grep LANG= | cut -d "_" -f 1 | cut -d "\"" -f 2 | tr [:upper:] [:lower:]`
if [ "$LANGLOCALE" = "es" ];then
    sed -i "s/UGET_LANG=\"en\"/UGET_LANG=\"es\"/" /etc/uget/ututo-get.conf
else
    sed -i "s/UGET_LANG=\"es\"/UGET_LANG=\"en\"/" /etc/uget/ututo-get.conf
fi

beepNSecs() {
	i=0
	while [ $i -lt $1 ]; do
		echo -en "$BEEP$i "; sleep 1s;
		i=$(( $i + 1 ))
	done
	echo " "
}

waitNSecs() {
	i=0
	while [ $i -lt $1 ]; do
		echo -en "$i "; sleep 1s;
		i=$(( $i + 1 ))
	done
	echo " "
}

# Imprime información general solo si el nivel de verbose lo permite
# Todos los parametros se imprimen
function eInfo() {
	printf "$@" >&2
}

autoupgradeUtutoGet()
{
	local UGETINSTALLSCRIPTDIR=/usr/sbin
	[ "$UTUTOGET_URL" = "" ] && UTUTOGET_URL="http://ututo.conmutador.net/svn.ututo.org/ututo-src/ututo-get/branches/reubicacion"
	echo -e "$LANG_UTUTOGETSH_NEWVERSION:$WHITE ${UTUTOGETSHLASTVERSION} $NO_COLOUR"
	echo -e "$LANG_UTUTOGET_WILLUPGRADE"
	for i in 1 2 3; do
		echo -en "$BEEP$i "; sleep 1s;
	done
	echo
	cd $UGETINSTALLSCRIPTDIR
	[ -f $UGETINSTALLSCRIPTDIR/autoinstalluget.sh ] && rm -f $UGETINSTALLSCRIPTDIR/autoinstalluget.sh
	echo "$GET --quiet $UTUTOGET_URL/autoinstalluget.sh"
	$GET --quiet $UTUTOGET_URL/autoinstalluget.sh
	chmod a+x $UGETINSTALLSCRIPTDIR/autoinstalluget.sh
	$UGETINSTALLSCRIPTDIR/autoinstalluget.sh $1
	echo "$LANG_FIXING..."
	fixUserGroups
	fixCFG00
	echo "$LANG_DONE"
	#exit 2
}

##############################################################################
# Load configuration settings and erase all patch files
rm -rf /usr/portage/packages/All/*.tar.bz2 2>/dev/null
rm -rf /usr/portage/packages/All/*.desktop 2>/dev/null
rm -rf /usr/portage/packages/All/xdm 2>/dev/null

CONF="/etc/uget/ututo-get.conf"
if [ -e "$CONF" ];then
	. $CONF
elif [ -e $CONFIGDIR/ututo-get.conf ]; then
	. $CONFIGDIR/ututo-get.conf
else
    echo " "
    echo -e "\aError $CONF not found."
    echo " "
    autoupgradeUtutoGet
fi
GET="$GET_PROGRAM $GET_OPTIONS"
GETPKG="$GET_PROGRAM_PKG $GET_OPTIONS_PKG"

if [ -f $UGETDIR/lang/ututo-get.es.msg ]; then
	. $UGETDIR/lang/ututo-get.es.msg
	if [ -f $UGETDIR/lang/ututo-get.$UGET_LANG.msg ]; then
		. $UGETDIR/lang/ututo-get.$UGET_LANG.msg
	else
	echo " "
	echo -e "\aError $UGETDIR/lang/ututo-get.$UGET_LANG.msg no encontrado. Los mensajes se leerán en Español"
	echo " "
	fi
else
    echo " "
    echo -e "\aError $UGETDIR/lang/ututo-get.es.msg no encontrado. No se puede continuar porque sería riesgoso."
	echo -e "Intentaré actualizar ututo-get para instalar los archivos de idioma."
	echo -e "\aError $UGETDIR/lang/ututo-get.es.msg not found. Can not continue, it could be dangerous."
    echo -e "I'll try to reinstall ututo-get to install the language files."
    echo " "
    sleep 2
    autoupgradeUtutoGet
    exit 1
fi


ACTION="$1"


##############################################################################
# FUNCION: select_processor
#
# Función para seleccionar el modelo de microprocesador. Presenta un men de
# opciones para que el usuario seleccione el modelo y una vez seleccionado
# guarda la configuración en el archivo $CONFIGDIR.conf
#

select_processor ()
{
   local OPTIONS="athlon-mp athlon-xp duron-athlon i486 i586 i686 k6-2 k6-3
   k8 pentium3 pentium4 sempron xeon64 NONE"

	echo -e "$WHITE"
	echo -e "$LANG_SELECT_PROCESSOR"
	echo -e "$NO_COLOUR"
	echo -e "`cat /proc/cpuinfo | grep "model name" | cut -d ":" -f 2`\n"

   select opt in $OPTIONS;
      do

         # Este if puede eliminarse si se crean enlaces al repositorio i486
         # en los servidores de descargas.
         if [ $opt = "i586" ] || [ $opt = "k6-2" ] || [ $opt = "k6-3" ]; then

            NEW_PROCESSOR="i486"

         elif [ $opt = "NONE" ]; then

            NEW_PROCESSOR="i686"

         else
            NEW_PROCESSOR="$opt"
         fi

         break
      done

   printf "$LANG_SELECTED_PROCESSOR" $opt
   sed -i '/^PROCESSOR=/s/'$PROCESSOR'/'$NEW_PROCESSOR'/' $CONF
   PROCESSOR=$NEW_PROCESSOR
}


##############################################################################
# FUNCION: leerProcesador
#
# Si el procesador no ha sido configurado llama a la funcion select_processor
# para presentar un men de opciones para seleccionar uno.
#

leerProcesador ()
{
	if [ "$PROCESSOR" = "NONE" ];then
   		select_processor
   		if [ "$PROCESSOR" = "NONE" ]; then
   			echo -e "$LANG_NO_PROCESSOR"
   			exit;exit;exit;
   		fi
	fi
}


##############################################################################
# Verifica si hay una nueva version en el repositorio

##############################################################################
# pkg.ututo.org is a pool of servers, but we must use only one of them for the
# whole install process, so we resolv the IPs and change the value of the 
# variables
FRAMEWORK=""
if [ "x$1" != "xinfo" ] && [ "x$1" != "xsearch" ] && [ "x$1" != "xcategory" ];then
   if [ "$SERVER_PKG" = "pkg.ututo.org" -o "$SERVER" = "pkg.ututo.org" -a "x$http_proxy" = "x" ]; then
	FRAMEWORK="pkg.ututo"
	PKGIP=$( dig @dns1.ututo.org pkg.ututo.org +short +time=2 | head -n 1 | grep -Eo "^(([0-9]){1,3}\.){3}([0-9]){1,3}$" 2>/dev/null )
	if [ "x$PKGIP" = "x" ]; then 
		PKGIP=$( dig @dns4.ututo.org pkg.ututo.org +short +time=2 | head -n 1 | grep -Eo "^(([0-9]){1,3}\.){3}([0-9]){1,3}$" 2>/dev/null )
	fi
	if [ "x$PKGIP" = "x" ]; then 
		PKGIP=$( dig @dns2.ututo.org pkg.ututo.org +short +time=2 | head -n 1 | grep -Eo "^(([0-9]){1,3}\.){3}([0-9]){1,3}$" 2>/dev/null )
	fi
	if [ "x$PKGIP" = "x" ]; then 
		PKGIP=$( dig @dns3.ututo.org pkg.ututo.org +short +time=2 | head -n 1 | grep -Eo "^(([0-9]){1,3}\.){3}([0-9]){1,3}$" 2>/dev/null )
	fi
	if [ "x$PKGIP" = "x" ]; then 
		PKGIP=$( dig pkg.ututo.org +short +time=2 | head -n 1 | grep -Eo "^(([0-9]){1,3}\.){3}([0-9]){1,3}$" 2>/dev/null )
	fi


	if [ "x$PKGIP" = "x" -a "x$http_proxy" = "x" ]; then 
		echo "$LANG_ERRORDNSPKG"
		exit 1
	else
		if [ $(grep "pkg.ututo.org" /etc/hosts | wc -l) -gt 0 ]; then
			sed -i "/pkg.ututo.org/s/^.*$/$PKGIP   pkg.ututo.org/" /etc/hosts
		else
			echo "$PKGIP   pkg.ututo.org" >> /etc/hosts
		fi
		PORT="80"
		if [ "$PKGIP" = "91.121.180.220" ];then
			PORT="82"
		fi
		SERVERBAK="$SERVER"
		SERVER="$SERVER:$PORT"
		PORTAGE_URL="$PROTOCOL://$SERVER:$PORT/ututo-portage"
		SERVER_PKG="$SERVER"
		SOURCESERVER="$SERVER"
		
		PWD=`pwd`
		rm -rf $PWD/SOURCES.LIST
		if [ -e $PWD/SOURCES.LIST ];then
		    sleep 0
		else
		    echo "Downloading SOURCES.LIST (Server 0:80)"
		    wget --quiet $GET_OPIONS pkg00.ututo.org/SOURCES.LIST > /dev/null
		fi
		if [ -e $PWD/SOURCES.LIST ];then
		    sleep 0
		else
		    echo "Downloading SOURCES.LIST (Server 1:80)"
		    wget --quiet $GET_OPTIONS pkg01.ututo.org/SOURCES.LIST > /dev/null
		fi
		if [ -e $PWD/SOURCES.LIST ];then
		    sleep 0
		else
		    echo "Downloading SOURCES.LIST (Server 2:80)"
		    wget --quiet $GET_OPTIONS pkg02.ututo.org:80/SOURCES.LIST > /dev/null
		fi

		if [ -e $PWD/SOURCES.LIST ];then
			ix=0
			ixm=33
			LIMIT=$((`cat $PWD/SOURCES.LIST | wc -l` / 2 + 1))
			TOT=$((`cat $PWD/SOURCES.LIST | wc -l`))
			if [ $LIMIT -gt 8  ];then
			    LIMIT=8
			    echo "Lookiing for $LIMIT download servers"
			else
			    echo "Lookiing for $LIMIT download servers"
			fi
			BESTIP=""
			BESTLAT=9999
			while [ $ix -lt $LIMIT ]; do
			    SERIAL=$(( `date +%s` % TOT ))
			    if [ "$SERIAL" = "0" ];then
				SERIAL="1"
			    fi
			    ixm=$(( ixm + 3 ))
			    LINEA=$(( SERIAL % `cat $PWD/SOURCES.LIST | wc -l` + 1 ))
			    PKGIP=`cat $PWD/SOURCES.LIST | head -n $SERIAL | tail -n 1 | cut -d ":" -f 2`
			    SOURCELIST=`cat $PWD/SOURCES.LIST | head -n $SERIAL | tail -n 1`
			    SOURCEREPO=`echo $SOURCELIST | cut -d ":" -f 6`
			    SOURCESERVER=`echo $SOURCELIST | cut -d ":" -f 5`
			    leerProcesador
			    #echo "seleccion: $LINEA ($SERIAL) IP: $PKGIP $ixm"
			    #echo "Proc: $PROCESSOR"
			    #echo "SOURCEREPO: $SOURCEREPO"
			    #sleep 1000
			    if [ $(echo "$SOURCEREPO" | grep "$PROCESSOR" | wc -l) -lt 1 ]; then
				echo "-------------------------------------------------------------------------------------------"
				echo "Repository $PROCESSOR not available in server $SOURCESERVER. Selecting another server..."
				echo "-------------------------------------------------------------------------------------------"
				sleep 1
			    else
				if [ "$PKGIP" != "$BESTIP" ];then
				    ix=$(( $ix + 1 ))
				    echo "Repositories availables: $SOURCEREPO"
				    echo -en "Analizing performance for $SOURCESERVER($SERIAL) (try $ix of $LIMIT)(testing for 4 seconds)... "
				    #LATENCY=`ping -c 1 $SOURCESERVER | grep "time=" | head -n 1 | cut -d "=" -f 4`
				    LATENCY=`LANGUAGE="en" LANG="en" ping -s 1016 -c 2 -i 2 $SOURCESERVER | grep "rtt " | cut -d "=" -f 2 | cut -d "/" -f 2`
				    echo -en "$LATENCY ms"
				    LATENCY=$(( `echo $LATENCY | cut -d "." -f 1 | cut -d " " -f 1` + 0 ))
				    ixm=$(( ixm + LATENCY ))
				    if [ $LATENCY -lt 1 ];then
					echo "Server fail for $SOURCESERVER($SERIAL) (try $ix of $LIMIT)"
					ix=$(( $ix - 1 ))
                                    else
					if [ $LATENCY -lt $BESTLAT ];then
					    BESTIP="$PKGIP"
					    BESTLAT="$LATENCY"
					    POSICION="$SERIAL"
					    echo " -Best latency (index $LATENCY ms)"
					else
					    echo "               (index $LATENCY ms)"
					fi
				    fi
				else
				    echo "Auto selected same server (Selected now $PKGIP = Selected before $BESTIP)"
				    echo "Restarting process to select diferent server..."
				    sleep 1
				fi
			    fi
			done

			echo "Analizing SOURCES.LIST..."
			SOURCELIST=`cat $PWD/SOURCES.LIST | head -n $POSICION | tail -n 1`
			PKGIP="$BESTIP"
			rm -rf $PWD/SOURCES.LIST
			SOURCEPROTOCOL=`echo $SOURCELIST | cut -d ":" -f 1`
			SOURCEDIR=`echo $SOURCELIST | cut -d ":" -f 3`
			SOURCEPORT=`echo $SOURCELIST | cut -d ":" -f 4`
			SOURCESERVER=`echo $SOURCELIST | cut -d ":" -f 5`
			SOURCEREPO=`echo $SOURCELIST | cut -d ":" -f 6`

			SERVER="$SOURCESERVER$SOURCEDIR:$SOURCEPORT"
			PROTOCOL="$SOURCEPROTOCOL"
			SERVER_PKG="$SERVER"
			PORTAGE_URL="$PROTOCOL://$SERVER/ututo-portage"
			UTUTOGET_URL="$PROTOCOL://$SERVER/svn.ututo.org/ututo-src/ututo-get/trunk"
		fi

		DISPONIBLES_URL="$PROTOCOL://$SERVER/paquetes"
		#LATENCY=`ping -c 1 $SOURCESERVER | grep "time=" | head -n 1 | cut -d "=" -f 4`
		#LATENCY=`LANGUAGE="en" LANG="en" ping -s 1016 -c 2 -i 2 $SOURCESERVER | grep "rtt " | cut -d "=" -f 2 | cut -d "/" -f 2`
		echo "------------------------------------------------------------------------------------"
		echo "Server selected is: $PROTOCOL://$SERVER ($POSICION)($PKGIP)($BESTLAT ms)"
		LANGUAGE="en" LANG="en" whois $PKGIP | grep "address:"
		echo "------------------------------------------------------------------------------------"
		wget --quiet $GET_OPTIONS $PROTOCOL://$SERVER/UTUTOLOCK.SYNC > /dev/null
		if [ -e UTUTOLOCK.SYNC ];then
			echo "Server $SERVER is locked because this repository is syncing"
			echo "Auto selected central download server packages.ututo.org:80"
			echo "Press CTRL+C to cancel or wait 10 seconds for using this server"
			SERVER="packages.ututo.org:80"
			PROTOCOL="http"
			SERVER_PKG="$SERVER"
			PORTAGE_URL="$PROTOCOL://$SERVER/ututo-portage"
			DISPONIBLES_URL="$PROTOCOL://$SERVER/paquetes"
			UTUTOGET_URL="$PROTOCOL://$SERVER/svn.ututo.org/ututo-src/ututo-get/trunk"
			rm -rf UTUTOLOCK.SYNC
			waitNSecs 10
		fi
# 		[ $SERVER = "pkg.ututo.org" ] && SERVER=$PKGIP
# 		[ $SERVER_PKG = "pkg.ututo.org" ] && SERVER_PKG=$PKGIP
	fi
   fi
else 
    SERVER="packages.ututo.org:80"
    PROTOCOL="http"
    SERVER_PKG="$SERVER"
    PORTAGE_URL="$PROTOCOL://$SERVER/ututo-portage"
    DISPONIBLES_URL="$PROTOCOL://$SERVER/paquetes"
    UTUTOGET_URL="$PROTOCOL://$SERVER/svn.ututo.org/ututo-src/ututo-get/trunk"
fi
##
## Test maintenance operation in default server
##
wget --quiet $GET_OPTIONS $PROTOCOL://$SERVER/UTUTOLOCK.SYNC > /dev/null
if [ -e UTUTOLOCK.SYNC ];then
    clear 
    echo "==========================================================================================="
    echo "==========================================================================================="
    echo " "
    echo "UTUTO Project global repository for server $SERVER is during maintenance operations"
    echo "UTUTO Global repository  will be available at soon as possible."
    echo " "
    echo "Apologize for all inconveniences. Try again later please. Thanks!"
    echo " "
    echo "==========================================================================================="
    echo "==========================================================================================="
    rm -rf UTUTOLOCK.SYNC
    exit ; exit ; exit
fi
## End test maintenance
##############################################################################
# Verifica si hay una nueva version en el repositorio de UTUTO XS
if [ "x$1" != "xinfo" ] && [ "x$1" != "xsearch" ] && [ "x$1" != "xcategory" ];then
  DIRORIGINAL=`pwd`
  cd /tmp
  rm -rf ututo.lastversion.*
  rm -rf ututo.lastversion
  wget --quiet $GET_OPTIONS $PROTOCOL://$SERVER/utiles/skels/ututo.lastversion.$REPOSITORIO
  mv ututo.lastversion.$REPOSITORIO /ututo.lastversion.$REPOSITORIO
  cd $DIRORIGINAL
  if [ -e /ututo.lastversion ];then
    VERSA=`cat /ututo.lastversion`
    VERSN=`cat /ututo.lastversion.$REPOSITORIO`
    if [ "$VERSA" != "$VERSN"  ];then
      if [ "$VERSA" != "UTUTOXS (Testing-Devel)" ];then
	echo "-------------------------------------------------------------------------------------------"
	echo "-------------------------------------------------------------------------------------------"
	echo "Nueva version disponible (New version available): $VERSN"
	echo "Version actual (Actual version)                             : $VERSA"
	echo " "
	echo "Para ACTUALIZAR a la nueva version ejecute :  uget xs-update  ($VERSA -> $VERSN)"
	echo "To UPDATE new version execute              :  uget xs-update  ($VERSA -> $VERSN)"
	echo " "
	echo "NOTA: Al actualizar se establecen parametros a sus valores por defecto"
	echo "      Si desea conservar alguna configuracion guarde una copia de resguardo previamente"
	echo " "
	echo "NOTE: Upgrade set system parameters to default values."
	echo "      To keep old configurations or data make a backup previously"
	echo "-------------------------------------------------------------------------------------------"
	echo "-------------------------------------------------------------------------------------------"
	rm -rf /ututo.lastversion,$REPOSITORIO
	sleep 4
      else
	echo "-------------------------------------------------------------------------------------------"
	echo "-------------------------------------------------------------------------------------------"
	echo "Usted esta usando la rama DEVEL del repositorio de UTUTO XS"
	echo "You are using DEVEL in UTUTO XS repository"
	echo "-------------------------------------------------------------------------------------------"
	echo "-------------------------------------------------------------------------------------------"
	sleep 4
      fi
    fi
  else
    echo "XS2012" > /ututo.lastversion
    rm -rf /ututo.lastversion.$REPOSITORIO
  fi
fi

##############################################################################
# Renice ututo-get according to configuration
renice $NICELEVEL $$ >/dev/null

##############################################################################
# Make a temporal working directory
ugettmpdir="/tmp/uget-$$"
mkdir -p $ugettmpdir

##############################################################################
# FUNCION: uso
#
# Muestra indicaciones b�icas sobre el uso de UTUTO-Get
#

uso()
{
   echo -e "$LANG_SINTAX_BASIC"
	echo " "

}



###############################################################################
# Si encuentra varios scripts que coinciden con el parámetro del usuario, muestra la lista y solicita al usuario que seleccione uno
#SIMILARES=`ls -1 $REPOSDIR/scripts/ | sed "s/\/usr\/ututo\/scripts\///" | grep -e "^$2" | sed "s/[.]sh//" | sort`
seleccionarPaquete ()
{
# set -x
	
	cd $REPOSDIR/scripts/
	local filtro="$1*.sh"
	local similares=($(ls -1v $filtro 2>/dev/null))
	if [[ $similares = "" ]]; then
		local filtro="*$1*.sh"
		local similares=($(ls -1v $filtro 2>/dev/null))
	fi
	
	local similaressinversion="$(ls -1v $filtro 2>/dev/null | sed -r "s/-[0-9\.]*([a-z])?(((_alpha|_rc|_pre|_p|_r|_beta)([0-9])*)?(\.|-|_)[a-z]*[0-9]+)?\.sh$//"  | uniq | wc -l 2> /dev/null)"
	if [[ $similaressinversion -gt 1 ]]; then
		eInfo "$LANG_SELECT_PACKAGE\n" 
		select PACK in ${similares[*]//\.sh/}
		do
			break
		done
		echo ${PACK}
		return 1
	fi
	
	for ((i=0; i<${#similares[*]}; i++));
	do
		similares[i]=$(echo ${similares[$i]} | sed -r -e "s/(-[0-9.]+)_alpha/\1_000_/" \
													  -e "s/(-[0-9.]+)_beta/\1_001_/" \
													  -e "s/(-[0-9.]+)_pre/\1_002_/" \
													  -e "s/(-[0-9.]+)_rc/\1_003_/" \
													  -e "s/(-[0-9.]+)_r[0-9]/\1_004_/")
		similares[i]=$(echo ${similares[$i]} | sed -r -e "s/([a-zA-Z0-9_-]+-[0-9.]+)(_alpha|_rc|_pre|_p|_r|_beta)/\1_?/" -e "s/.sh$/.0.sh/")
		touch $ugettmpdir/${similares[$i]}
	done
	cd $ugettmpdir
	local -a versionesdisponibles="$(ls -1v $filtro 2>/dev/null | sed -r -e "s/(-[0-9.]+)\.0(_alpha|_rc|_pre|_p|_r|_beta)/\1/" \
										-e "s/(-[0-9.]+)_000_/\1_alpha/" \
										-e "s/(-[0-9.]+)_001_/\1_beta/" \
										-e "s/(-[0-9.]+)_002_/\1_pre/" \
										-e "s/(-[0-9.]+)_003_/\1_rc/" \
										-e "s/(-[0-9.]+)_004_/\1_r/" \
										-e "s/\.0\.sh$//" \
										-e "s/\.sh$//")"
# 	set -x
	local versionmasnueva=$(echo "$versionesdisponibles" | tail -n 1)
	if [[ $(echo "$versionesdisponibles" | wc -l) -gt 1 ]]; then
		eInfo "$LANG_SELECT_LAST_PACKAGE" "$versionmasnueva"
		eInfo "$LANG_INSTALL_DEFAULT" "$versionmasnueva"
		read -s -n1 -t $TOUT CONFIRMA
		if [[ "$CONFIRMA" = "Y" || "$CONFIRMA" = "y" || "$CONFIRMA" = "" ]]; then
			echo "$versionmasnueva"
		else
			eInfo "$LANG_SELECT_PACKAGE\n"
			select PACK in ${versionesdisponibles}
			do
				if [[ "$PACK" = "NONE/CANCEL" ]]; then
					eInfo "$LANG_CANCELEDBYUSER\n"
					echo ""
				fi
				break
			done
			echo $PACK
		fi
	else
		echo $versionmasnueva
	fi
	
	rm $ugettmpdir/$filtro 2>/dev/null
# set +x
}

###############################################################################
# Obtiene la lista de dependencias desde el script de instalaci� generado por el kit de desarrollo
obtenerDependencias() {

	local version=`grep -e 'PROGRAMA.=\".*\"' $REPOSDIR/scripts/$PACK.sh | wc -l`

	if [ $version -gt 0 ]; then

		PROGRAMAS=`grep -e 'PROGRAMA.*=\".*\"' $REPOSDIR/scripts/$PACK.sh | sed "s/\"//g"`
		URLS=`grep -e 'wget -c https://$SERVER/$PROCESSOR/$PROGRAMA' $REPOSDIR/scripts/$PACK.sh | grep -v ".sig[1,2]" | sed "s/ &>\/dev\/null//" | sed "s/\/usr\/bin\/wget -c //" | sed "s/[ ]*//" | sed "s/.sig1//" | sed "s/[$]SERVIDOR/$SERVER_PKG/" | sed "s/[$]RES/$PROCESSOR/"`
		for P in $PROGRAMAS
		do
			P1=${P/=*/}
			P2=${P/PROGRAMA*=/}
			URLS=${URLS/\$$P1/$P2}
		done
		PAQUETES=$URLS
	else
		PAQUETES=`cat $REPOSDIR/scripts/$PACK.sh | grep ".*.tbz2.sig1" | sed "s/ &>\/dev\/null//" | sed "s/\/usr\/bin\/wget -c //" | sed "s/[ ]*//" | sed "s/.sig1//" | sed "s/[$]SERVIDOR/$SERVER_PKG/" | sed "s/[$]RES/$PROCESSOR/" | sed "s/.*libstdc.*$//"`
	fi

	if [ "x$ACTION" = "xfastinstall" -o "x$ACTION" = "xfastreinstall" ]; then
		PACK2="`echo $PACK | cut -d "." -f 1 `"
	        PAQUETES="`echo "$PAQUETES" | grep $PACK2`"
	        # PAQUETES="https://$SERVER/$PROCESSOR/$PACK.tbz2"
	fi

}

###############################################################################
# Verfica los paquetes descargados con las firmas
verificaFirmas() {
	local PAQUETESFALLADOS
	local paquete
	local PAQUETE2
	local aux

	cd $PKGDIR
	FALLAVERIFICACIONGLOBAL=""
	echo Analizing Packages...
	for paquete in $AINSTALAR
	do
		FALLAVERIFICACIONPAQUETE=""
		PAQUETE2=`echo $paquete | grep ".sig"`
		paquete=`echo $paquete | sed "s/http.*\///" | sed "s/.tbz2//"`

		# Si el paquete no descarg�por algn motivo, pregunta al usuario si desea continuar o cancelar
		if [ -f "$paquete.tbz2" ]; then
			echo --------------------------------------
			echo Package: $paquete
			LANGUAGE=\"us\" gpg --verify $paquete.tbz2.sig1 $paquete.tbz2 2> /sign1
			LANGUAGE=\"us\" gpg --verify $paquete.tbz2.sig2 $paquete.tbz2 2> /sign2
			SIGN1=`cat /sign1`
			SIGN2=`cat /sign2`
			rm -f /sign1
			rm -f /sign2
			ANASIG1=`echo $SIGN1 | grep "No public key"`
			ANASIG2=`echo $SIGN2 | grep "No public key"`
			if [ "$ANASIG1" != "" -o "$ANASIG2" != "" ];then
				rm -rf clave-ututo-1.asc
				rm -rf clave-ututo-2.asc
				wget $GET_OPTIONS http://www.ututo.org/utiles/skels/clave-ututo-1.asc
				wget $GET_OPTIONS http://www.ututo.org/utiles/skels/clave-ututo-2.asc
				gpg --import clave-ututo-1.asc
				gpg --import clave-ututo-2.asc
				rm -rf clave-ututo-1.asc
				rm -rf clave-ututo-2.asc
				LANGUAGE=\"us\" gpg --verify $paquete.tbz2.sig1 $paquete.tbz2 2> /sign1
				LANGUAGE=\"us\" gpg --verify $paquete.tbz2.sig2 $paquete.tbz2 2> /sign2
				SIGN1=`cat /sign1`
				SIGN2=`cat /sign2`
				rm -f /sign1
				rm -f /sign2
			fi
			ANASIG1=`echo $SIGN1 | grep "No public key"`
			ANASIG2=`echo $SIGN2 | grep "No public key"`
			if [ "$ANASIG1" != "" -o "$ANASIG2" != "" ];then
				FALLAVERIFICACIONPAQUETE="error"
			fi
			ANASIG1=`echo $SIGN1 | grep "error"`
			ANASIG2=`echo $SIGN2 | grep "error"`
			if [ "$ANASIG1" != "" -o "$ANASIG2" != "" ];then
				FALLAVERIFICACIONPAQUETE="error"
			fi
			ANASIG1=`echo $SIGN1 | grep "not be verified"`
			ANASIG2=`echo $SIGN2 | grep "not be verified"`
			if [ "$ANASIG1" != "" -o "$ANASIG2" != "" ];then
				FALLAVERIFICACIONPAQUETE="error"
			fi
			ANASIG1=`echo $SIGN1 | grep "BAD signature"`
			ANASIG2=`echo $SIGN2 | grep "BAD signature"`
			if [ "$ANASIG1" != "" -o "$ANASIG2" != "" ];then
				FALLAVERIFICACIONPAQUETE="error"
			fi
			if [ "$FALLAVERIFICACIONPAQUETE" != "error" ]; then
				echo "$LANG_GPG_OK"
			else
				FALLAVERIFICACIONGLOBAL="error"
				echo "$LANG_GPG_ERROR"
				echo $ANASIG1
				rm -f $paquete.tbz2
				rm -f $paquete.tbz2.sig1
				rm -f $paquete.tbz2.sig2
				PAQUETESFALLADOS="$PAQUETESFALLADOS $paquete"
			fi
			echo --------------------------------------
		else
			PAQUETESFALLADOS="$PAQUETESFALLADOS $paquete"
			FALLAVERIFICACIONGLOBAL="error"
			echo -e "$BEEP"
			printf "$LANG_GPG_NOTFOUNDREQUIRED" $paquete
			read -t $TOUT -p "$LANG_GPG_CONTINUEDOWNLOAD" CONFIRMA
			if [ "$CONFIRMA" = "n" -o "$CONFIRMA" = "N" ]; then
				printf "$LANG_GPG_NOTFOUNDCANCELLING" $paquete
				exit
			fi
		fi
	done

	if [ "$FALLAVERIFICACIONGLOBAL" = "error" ]; then
		echo -e "$LANG_GPG_RESTARTINSTALLATION"
		echo -e "$LANG_GPG_REPORT"
		echo "------------------"
		echo "SCRIPT: $REPOSITORIO/$PACK"
		echo "PROCESSOR: $PROCESSOR"
		echo "------------------"
		for aux in $PAQUETESFALLADOS; do
			echo $aux
		done
		echo "------------------"
		DA_NOTFOUND=`ps ax | grep dist-upgrade | grep -v grep`
		if [ DA_NOTFOUND != "" ];then
			FECHA=`date`
			echo "PACKAGE NOT FOUND - $FECHA  - Command executed: uget $1 $2" >> /dist-upgrade.notfound
			echo "SCRIPT: $REPOSITORIO/$PACK" >> /dist-upgrade.notfound
			echo "PROCESSOR: $PROCESSOR" >> /dist-upgrade.notfound
			echo "------------------" >> /dist-upgrade.notfound
			for aux in $PAQUETESFALLADOS; do
			    echo $aux >> /dist-upgrade.notfound
			done
			echo "---------------------------------------------------------------------------------------" >> /dist-upgrade.notfound
		fi 

		exit; exit; exit;
	fi

}

###############################################################################
# Verifica que emerge haya completado y el paquete est�en la base de paquetes instalados
verificarEmergeRealizado() {

	local P3=${1/\.tbz2/}
	instalado=`find /var/db/pkg/ -name $P3.ebuild`
	pqtfail=`echo $P3 | grep "glibc-"`
	if [ "x$instalado" = "x" ] && [ "x$pqtfail" = "x" ]; then
		printf "$LANG_EMERGEFAILED" $P3
		beepNSecs 5
# 		echo -e "$LANG_UNTARAFTERFAILEDEMERGE"
# 		printf "$LANG_CONFIRMORCANCEL" 
# 		read -t $TOUT CONFIRMA
# 		if [ "x$CONFIRMA" = "xy" -o "x$CONFIRMA" = "xY" -o "x$CONFIRMA" = "x" ]; then
			cd $PKGDIR
			tar xvjpf $1 -C /
# 		fi
	fi
}

fixPortageDB() {
	find /var/db/pkg/ -iname '-MERGING*lockfile' -exec rm {} \;
	mv /var/db/pkg/openrc-ututo* /tmp/
	/usr/lib/portage/bin/fix-db.py 2> /dev/null
	mv /tmp/openrc-ututo* /var/db/pkg/
}

fixCFG00() {
    echo -n "Processing config files..."
    ls -1 /etc/init.d/.*cfg00* > /tmp/listado-paquetes 2>/dev/null
    while read archivo
    do
        echo -n $archivo
	new_archivo=`echo $archivo | cut -d "/" -f 4 | cut -d "." -f 2 | cut -d "_" -f 3`
	echo " ->> "$new_archivo
	mv $archivo /etc/init.d/$new_archivo
	chown root:root /etc/init.d/$new_archivo
	chmod 755 /etc/init.d/$new_archivo
    done < /tmp/listado-paquetes
    rm -rf /tmp/listado-paquetes

    echo -n "*"
    ls -1 /etc/dbus-1/.*cfg00* > /tmp/listado-paquetes 2>/dev/null
    while read archivo
    do
        echo -n $archivo
	new_archivo=`echo $archivo | cut -d "/" -f 4 | cut -d "_" -f 3`
	echo " ->> "$new_archivo
	mv $archivo /etc/dbus-1/$new_archivo
	chown root:root /etc/dbus-1/$new_archivo
	chmod 644 /etc/dbus-1/$new_archivo
    done < /tmp/listado-paquetes
    rm -rf /tmp/listado-paquetes

    echo -n "*"
    ls -1 /etc/dbus-1/system.d/.*cfg00* > /tmp/listado-paquetes 2>/dev/null
    while read archivo
    do
        echo -n $archivo
	new_archivo=`echo $archivo | cut -d "/" -f 5 | cut -d "_" -f 3`
	echo " ->> "$new_archivo
	mv $archivo /etc/dbus-1/system.d/$new_archivo
	chown root:root /etc/dbus-1/system.d/$new_archivo
	chmod 644 /etc/dbus-1/system.d/$new_archivo
    done < /tmp/listado-paquetes
    rm -rf /tmp/listado-paquetes

    echo -n "*"
    ls -1 /etc/pulse/.*cfg00* > /tmp/listado-paquetes 2>/dev/null
    while read archivo
    do
        echo -n $archivo
	new_archivo=`echo $archivo | cut -d "/" -f 4 | cut -d "_" -f 3`
	echo " ->> "$new_archivo
	mv $archivo /etc/pulse/$new_archivo
	chown root:root /etc/pulse/$new_archivo
	chmod 644 /etc/pulse/$new_archivo
    done < /tmp/listado-paquetes
    rm -rf /tmp/listado-paquetes

    echo -n "*"
    ls -1 /etc/openldap/.*cfg00* 2>/dev/null | grep -v "ldap.conf" | grep -v "slapd.conf" > /tmp/listado-paquetes 2>/dev/null
    while read archivo
    do
        echo -n $archivo
	new_archivo=`echo $archivo | cut -d "/" -f 4 | cut -d "_" -f 3`
	echo " ->> "$new_archivo
	mv $archivo /etc/openldap/$new_archivo
	chown root:root /etc/openldap/$new_archivo
	chmod 644 /etc/openldap/$new_archivo
    done < /tmp/listado-paquetes
    rm -rf /tmp/listado-paquetes

    echo -n "*"
    ls -1 /etc/openldap/schema/.*cfg00* > /tmp/listado-paquetes 2>/dev/null
    while read archivo
    do
        echo -n $archivo
	new_archivo=`echo $archivo | cut -d "/" -f 5 | cut -d "_" -f 3`
	echo " ->> "$new_archivo
	mv $archivo /etc/openldap/schema/$new_archivo
	chown root:root /etc/openldap/schema/$new_archivo
	chmod 644 /etc/openldap/schema/$new_archivo
    done < /tmp/listado-paquetes
    rm -rf /tmp/listado-paquetes

    echo -n "*"
    ls -1 /etc/openvpn/.*cfg00* > /tmp/listado-paquetes 2>/dev/null
    while read archivo
    do
        echo -n $archivo
	new_archivo=`echo $archivo | cut -d "/" -f 4 | cut -d "_" -f 3`
	echo " ->> "$new_archivo
	mv $archivo /etc/openvpn/$new_archivo
	chown root:root /etc/openvpn/$new_archivo
	chmod 644 /etc/openvpn/$new_archivo
    done < /tmp/listado-paquetes
    rm -rf /tmp/listado-paquetes

    echo -n "*"
    ls -1 /etc/fonts/conf.avail/.*cfg00* > /tmp/listado-paquetes 2>/dev/null
    while read archivo
    do
        echo -n $archivo
	new_archivo=`echo $archivo | cut -d "/" -f 5 | cut -d "_" -f 3`
	echo " ->> "$new_archivo
	mv $archivo /etc/fonts/conf.avail/$new_archivo
	chown root:root /etc/fonts/conf.avail/$new_archivo
	chmod 644 /etc/fonts/conf.avail/$new_archivo
    done < /tmp/listado-paquetes
    rm -rf /tmp/listado-paquetes

    echo -n "*"
    ls -1 /etc/xdg/compiz/.*cfg00* > /tmp/listado-paquetes 2>/dev/null
    while read archivo
    do
        echo -n $archivo
	new_archivo=`echo $archivo | cut -d "/" -f 5 | cut -d "_" -f 3`
	echo " ->> "$new_archivo
	mv $archivo /etc/xdg/compiz/$new_archivo
	chown root:root /etc/xdg/compiz/$new_archivo
	chmod 644 /etc/xdg/compiz/$new_archivo
    done < /tmp/listado-paquetes
    rm -rf /tmp/listado-paquetes

    echo -n "*"
    ls -1 /etc/sound/events/.*cfg00* > /tmp/listado-paquetes 2>/dev/null
    while read archivo
    do
        echo -n $archivo
	new_archivo=`echo $archivo | cut -d "/" -f 5 | cut -d "_" -f 3`
	echo " ->> "$new_archivo
	mv $archivo /etc/sound/events/$new_archivo
	chown root:root /etc/sound/events/$new_archivo
	chmod 644 /etc/sound/events/$new_archivo
    done < /tmp/listado-paquetes
    rm -rf /tmp/listado-paquetes

    echo -n "*"
    ls -1 /etc/hotplug/.*cfg00* > /tmp/listado-paquetes 2>/dev/null
    while read archivo
    do
        echo -n $archivo
	new_archivo=`echo $archivo | cut -d "/" -f 4 | cut -d "_" -f 3`
	echo " ->> "$new_archivo
	mv $archivo /etc/hotplug/$new_archivo
	chown root:root /etc/hotplug/$new_archivo
	chmod 644 /etc/hotplug/$new_archivo
    done < /tmp/listado-paquetes
    rm -rf /tmp/listado-paquetes

    echo -n "*"
    ls -1 /etc/hotplug/usb/.*cfg00* > /tmp/listado-paquetes 2>/dev/null
    while read archivo
    do
        echo -n $archivo
	new_archivo=`echo $archivo | cut -d "/" -f 5 | cut -d "_" -f 3`
	echo " ->> "$new_archivo
	mv $archivo /etc/hotplug/usb/$new_archivo
	chown root:root /etc/hotplug/usb/$new_archivo
	chmod 644 /etc/hotplug/usb/$new_archivo
    done < /tmp/listado-paquetes
    rm -rf /tmp/listado-paquetes

    echo -n "*"
    ls -1 /etc/sane.d/.*cfg00* 2>/dev/null | grep -v "saned.conf" > /tmp/listado-paquetes 2>/dev/null
    while read archivo
    do
        echo -n $archivo
	new_archivo=`echo $archivo | cut -d "/" -f 4 | cut -d "_" -f 3`
	echo " ->> "$new_archivo
	mv $archivo /etc/sane.d/$new_archivo
	chown root:root /etc/sane.d/$new_archivo
	chmod 644 /etc/sane.d/$new_archivo
	mv /etc/sane.d/umax /etc/sane.d/umax_pp.conf 2>/dev/null
    done < /tmp/listado-paquetes
    rm -rf /tmp/listado-paquetes

    echo -n "*"
    ls -1 /etc/hal/fdi/policy/.*cfg00* > /tmp/listado-paquetes 2>/dev/null
    while read archivo
    do
        echo -n $archivo
	new_archivo=`echo $archivo | cut -d "/" -f 6 | cut -d "_" -f 3`
	echo " ->> "$new_archivo
	mv $archivo /etc/hal/fdi/policy/$new_archivo
	chown root:root /etc/hal/fdi/policy/$new_archivo
	chmod 644 /etc/hal/fdi/policy/$new_archivo
    done < /tmp/listado-paquetes
    rm -rf /tmp/listado-paquetes

    echo -n "*"
    ls -1 /etc/udev/rules.d/.*cfg00* > /tmp/listado-paquetes 2>/dev/null
    while read archivo
    do
        echo -n $archivo
	new_archivo=`echo $archivo | cut -d "/" -f 5 | cut -d "_" -f 3`
	echo " ->> "$new_archivo
	mv $archivo /etc/udev/rules.d/$new_archivo
	chown root:root /etc/udev/rules.d/$new_archivo
	chmod 644 /etc/udev/rules.d/$new_archivo
    done < /tmp/listado-paquetes
    rm -rf /tmp/listado-paquetes

    echo -n "*"
    ls -1 /etc/PolicyKit/.*cfg00* > /tmp/listado-paquetes 2>/dev/null
    while read archivo
    do
        echo -n $archivo
	new_archivo=`echo $archivo | cut -d "/" -f 4 | cut -d "_" -f 3`
	echo " ->> "$new_archivo
	mv $archivo /etc/PolicyKit/$new_archivo
	chown root:root /etc/PolicyKit/$new_archivo
	chmod 644 /etc/PolicyKit/$new_archivo
    done < /tmp/listado-paquetes
    rm -rf /tmp/listado-paquetes

    echo -n "*"
    ls -1 /etc/UPower/.*cfg00* > /tmp/listado-paquetes 2>/dev/null
    while read archivo
    do
        echo -n $archivo
	new_archivo=`echo $archivo | cut -d "/" -f 4 | cut -d "_" -f 3`
	echo " ->> "$new_archivo
	mv $archivo /etc/UPower/$new_archivo
	chown root:root /etc/UPower/$new_archivo
	chmod 644 /etc/UPower/$new_archivo
    done < /tmp/listado-paquetes
    rm -rf /tmp/listado-paquetes

    echo -n "*"
    ls -1 /etc/xdg/autostart/.*cfg00* > /tmp/listado-paquetes 2>/dev/null
    while read archivo
    do
        echo -n $archivo
	new_archivo=`echo $archivo | cut -d "/" -f 5 | cut -d "_" -f 3`
	echo " ->> "$new_archivo
	mv $archivo /etc/xdg/autostart/$new_archivo
	chown root:root /etc/xdg/autostart/$new_archivo
	chmod 644 /etc/xdg/autostart/$new_archivo
    done < /tmp/listado-paquetes
    rm -rf /tmp/listado-paquetes

    echo -n "*"
    ls -1 /etc/xdg/exaile/.*cfg00* > /tmp/listado-paquetes 2>/dev/null
    while read archivo
    do
        echo -n $archivo
	new_archivo=`echo $archivo | cut -d "/" -f 5 | cut -d "_" -f 3`
	echo " ->> "$new_archivo
	mv $archivo /etc/xdg/exaile/$new_archivo
	chown root:root /etc/xdg/exaile/$new_archivo
	chmod 644 /etc/xdg/exaile/$new_archivo
    done < /tmp/listado-paquetes
    rm -rf /tmp/listado-paquetes

    echo -n "*"
    ls -1 /etc/xdg/lxsession/LXDE/.*cfg00* > /tmp/listado-paquetes 2>/dev/null
    while read archivo
    do
        echo -n $archivo
	new_archivo=`echo $archivo | cut -d "/" -f 6 | cut -d "_" -f 3`
	echo " ->> "$new_archivo
	mv $archivo /etc/xdg/lxsession/LXDE/$new_archivo
	chown root:root /etc/xdg/lxsession/LXDE/$new_archivo
	chmod 644 /etc/xdg/lxsession/LXDE/$new_archivo
    done < /tmp/listado-paquetes
    rm -rf /tmp/listado-paquetes

    echo -n "*"
    ls -1 /etc/xdg/menus/.*cfg00* > /tmp/listado-paquetes 2>/dev/null
    while read archivo
    do
        echo -n $archivo
	new_archivo=`echo $archivo | cut -d "/" -f 5 | cut -d "_" -f 3`
	echo " ->> "$new_archivo
	mv $archivo /etc/xdg/menus/$new_archivo
	chown root:root /etc/xdg/menus/$new_archivo
	chmod 644 /etc/xdg/menus/$new_archivo
    done < /tmp/listado-paquetes
    rm -rf /tmp/listado-paquetes

    echo -n "*"
    ls -1 /etc/xdg/midori/.*cfg00* > /tmp/listado-paquetes 2>/dev/null
    while read archivo
    do
        echo -n $archivo
	new_archivo=`echo $archivo | cut -d "/" -f 5 | cut -d "_" -f 3`
	echo " ->> "$new_archivo
	mv $archivo /etc/xdg/midori/$new_archivo
	chown root:root /etc/xdg/midori/$new_archivo
	chmod 644 /etc/xdg/midori/$new_archivo
    done < /tmp/listado-paquetes
    rm -rf /tmp/listado-paquetes

    echo -n "*"
    ls -1 /etc/xdg/openbox/.*cfg00* > /tmp/listado-paquetes 2>/dev/null
    while read archivo
    do
        echo -n $archivo
	new_archivo=`echo $archivo | cut -d "/" -f 5 | cut -d "_" -f 3`
	echo " ->> "$new_archivo
	mv $archivo /etc/xdg/openbox/$new_archivo
	chown root:root /etc/xdg/openbox/$new_archivo
	chmod 644 /etc/xdg/openbox/$new_archivo
    done < /tmp/listado-paquetes
    rm -rf /tmp/listado-paquetes

    echo -n "*"
    ls -1 /etc/xdg/pcmanfm/default/.*cfg00* > /tmp/listado-paquetes 2>/dev/null
    while read archivo
    do
        echo -n $archivo
	new_archivo=`echo $archivo | cut -d "/" -f 6 | cut -d "_" -f 3`
	echo " ->> "$new_archivo
	mv $archivo /etc/xdg/pcmanfm/default/$new_archivo
	chown root:root /etc/xdg/pcmanfm/default/$new_archivo
	chmod 644 /etc/xdg/pcmanfm/default/$new_archivo
    done < /tmp/listado-paquetes
    rm -rf /tmp/listado-paquetes

    echo -n "*"
    ls -1 /etc/xdg/xfce4/.*cfg00* > /tmp/listado-paquetes 2>/dev/null
    while read archivo
    do
        echo -n $archivo
	new_archivo=`echo $archivo | cut -d "/" -f 5 | cut -d "_" -f 3`
	echo " ->> "$new_archivo
	mv $archivo /etc/xdg/xfce4/$new_archivo
	chown root:root /etc/xdg/xfce4/$new_archivo
	chmod 644 /etc/xdg/xfce4/$new_archivo
    done < /tmp/listado-paquetes
    rm -rf /tmp/listado-paquetes

    echo -n "*"
    ls -1 /etc/xdg/xfce4/panel/.*cfg00* > /tmp/listado-paquetes 2>/dev/null
    while read archivo
    do
        echo -n $archivo
	new_archivo=`echo $archivo | cut -d "/" -f 6 | cut -d "_" -f 3`
	echo " ->> "$new_archivo
	mv $archivo /etc/xdg/xfce4/panel/$new_archivo
	chown root:root /etc/xdg/xfce4/panel/$new_archivo
	chmod 644 /etc/xdg/xfce4/panel/$new_archivo
    done < /tmp/listado-paquetes
    rm -rf /tmp/listado-paquetes

    echo -n "*"
    ls -1 /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/.*cfg00* > /tmp/listado-paquetes 2>/dev/null
    while read archivo
    do
        echo -n $archivo
	new_archivo=`echo $archivo | cut -d "/" -f 7 | cut -d "_" -f 3`
	echo " ->> "$new_archivo
	mv $archivo /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/$new_archivo
	chown root:root /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/$new_archivo
	chmod 644 /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/$new_archivo
    done < /tmp/listado-paquetes
    rm -rf /tmp/listado-paquetes

    echo -n "*"
    ls -1 /etc/.*cfg00* | grep -v "rc.conf" | grep -v "hosts" | grep -v "profile" 2>/dev/null > /tmp/listado-paquetes 2>/dev/null
    while read archivo
    do
        echo -n $archivo
	new_archivo=`echo $archivo | cut -d "/" -f 3 | cut -d "_" -f 3`
	echo " ->> "$new_archivo
	mv $archivo /etc/$new_archivo
	mv /etc/DIR /etc/DIR_COLORS 2>/dev/null
	chown root:root /etc/$new_archivo
	chmod 644 /etc/$new_archivo
    done < /tmp/listado-paquetes
    rm -rf /tmp/listado-paquetes

    rm -rf /etc/xdg/autostart/gnome-do.desktop
    ln -sf /usr/lib/virtualbox /usr/lib/virtualbox-ose
    echo " - Done."
}

fixUserGroups() {
	fixCFG00
	#echo "0 * * * * nice -n 19 /usr/bin/backintime --backup-job" > /tmp/cron
	echo "$LANG_FIXING/cron..."
	ls -1 /home/* | grep ":" | grep -v "usuario" | grep -v "ntp" | grep -v "p2p" | grep -v "mp3" | sed "s/://" | cut -d "/" -f 3 > /usuarios
	while read USER
	do
	    gpasswd -a $USER plugdev &>/dev/null
	    gpasswd -a $USER uucp &>/dev/null
	    gpasswd -a $USER audio &>/dev/null
	    gpasswd -a $USER cdrom &>/dev/null
	    gpasswd -a $USER dialout &>/dev/null
	    gpasswd -a $USER tape &>/dev/null
	    gpasswd -a $USER video &>/dev/null
	    gpasswd -a $USER cdrw &>/dev/null
	    gpasswd -a $USER usb &>/dev/null
	    gpasswd -a $USER users &>/dev/null
	    gpasswd -a $USER lp &>/dev/null
	    gpasswd -a $USER wheel &>/dev/null
	    gpasswd -a $USER disk &>/dev/null
	    gpasswd -a $USER realtime &>/dev/null
	    gpasswd -a $USER scanner &>/dev/null
	    gpasswd -a $USER tty &>/dev/null
	    gpasswd -a $USER netdev &>/dev/null
	    gpasswd -a $USER p2p &>/dev/null
	    gpasswd -a $USER avahi &>/dev/null
	    gpasswd -a $USER transmission &>/dev/null
	    gpasswd -a $USER cron &>/dev/null
	    gpasswd -a $USER crontab &>/dev/null
	    gpasswd -a $USER vboxusers &>/dev/null
	    chmod 757 /var/spool/cron/crontabs/
	    #crontab -u $USER /tmp/cron
	    done < /usuarios
	    rm -rf /usuarios
}

ocultarPortage() {
	[ ! -d $TMPUGETDIR ] && mkdir -p $TMPUGETDIR
	for portagedir in $(ls -1 /usr/portage/)
	do
		[ -d /usr/portage/$portagedir -a "x$portagedir" != "xprofiles" -a "x$portagedir" != "xeclass" -a "x$portagedir" != "xpackages" -a "x/usr/portage/$portagedir" != "x$TMPUGETDIR" ] && mv -f /usr/portage/$portagedir $TMPUGETDIR/
	done
}

restaurarPortage() {
	if [ -d $TMPUGETDIR ]; then
		for portagedir in $(ls -1 $TMPUGETDIR/)
		do
			[ -d $TMPUGETDIR/$portagedir ] && mv -f $TMPUGETDIR/$portagedir  /usr/portage/
		done
	fi
}

###############################################################################
# Ejecuta comandos post-instalación que requieren algunos paquetes, tomándolos del script generado por el kit
comandosPostInstalacion() {
	
	
	local LINEASTOTALES=`cat $REPOSDIR/scripts/$PACK.sh | wc -l`
	local LINEAINI=`cat $REPOSDIR/scripts/$PACK.sh | grep -n '^[ ]*/usr/bin/$INSTALAR $OPCION '$P2'.tbz2' | cut -d ":" -f 1 | head -n 1`
	local LINEATAIL=$(( LINEAINI - LINEASTOTALES ))
	local DIFE=`cat $REPOSDIR/scripts/$PACK.sh | tail -n $LINEATAIL | grep -n '^[ ]*/usr/bin/$INSTALAR $OPCION .*.tbz2' | head -n 1 | cut -d ":" -f 1 | head -n 1`
	if [ "$DIFE" = "" ]; then return 0; fi
	if [ $DIFE -gt 1 -a "x$LINEAINI" != "x" ]; then
# 		set -x
		echo "#!/bin/bash" > /postinstall.sh
		echo "source $CONF" >> /postinstall.sh
		if [ "$FRAMEWORK" = "pkg.ututo" ];then
		    echo "SERVER=\"$SOURCESERVER$SOURCEDIR:$SOURCEPORT\"" >> /postinstall.sh
		    echo "PROTOCOL=\"$SOURCEPROTOCOL\"" >> /postinstall.sh
		fi
		cat $REPOSDIR/scripts/$PACK.sh | tail -n $LINEATAIL | head -n $((DIFE - 1)) | sed -r "s/^[\t, ]*//g" | sed -r "s/wget.*https:/$GETPKG $GET_OPTIONS $PROTOCOL:/g" | sed -r "s/wget /$GETPKG $GET_OPTIONS /g" >> /postinstall.sh
		printf "$LANG_POSTINSTALLTASKS" $P2
		ln -sf /bin/bash /bin/sh
		sh /postinstall.sh
# 		set +x
		if [ "$DEBUG" = "1" ]; then
			echo "#### Postinstall tasks for $PACK / $P2 ####" >> /postinstall.backup
			echo -e "Lineas totales: $LINEASTOTALES\nLinea inicio: $LINEAINI\nLineaLinea final: $LINEATAIL" >> /postinstall.backup
			echo -e "-----------------------------------\n" >> /postinstall.backup
			cat /postinstall.sh >> /postinstall.backup
			echo -e "-----------------------------------\n" >> /postinstall.backup
# 			cat /postinstall.out >> /postinstall.backup
# 			echo -e "-----------------------------------\n" >> /postinstall.backup
		fi
	fi
	rm -rf /postinstall.sh
}

###############################################################################
# Ejecuta emerge para instalar los paquetes y ejecuta las acciones post-instalación, correctivas y de configuración que
# fueron generadas por el kit de desarrollo
instalarPaquetes () {

	cd $PKGDIR
	if [ "$PROCESSOR" = "i486" ]; then
		local PROC="i486"
	else
		local PROC="i686"
	fi
# 	$GET $PROTOCOL_PKG://$SERVER_PKG/$PROC/libstdc++-6.tar.bz2
#     	tar -xvjpf libstdc++-6.tar.bz2 -C /
#     	rm -f /usr/lib/libstdc++.so
#     	rm -f /usr/lib/libstdc++.so.6
#     	rm -f /usr/lib/libstdc++.so.6.0.0

	ocultarPortage

	NROPAQUETES=`echo $AINSTALAR |  wc -w`
	let AVANCE=0
	for P in $AINSTALAR
	do

		#P2=`echo $P | sed "s/http.*\///" | sed -r "s/-[0-9\.]*([a-z])?(((_alpha|_rc|_pre|_p|_r|_beta)([0-9])*)?(-|_)[a-z]+[0-9]+)?\.tbz2$//"`
		P2=`echo $P | sed "s/http.*\///"` # | sed -r "s/\.tbz2$//"`
		if [ "$P2" != "" ]; then

			## Esta aqui para prevenir que algun paquete lo instale y ponga lento el proceso
			mv /sbin/ldconfig /sbin/ldconfig.noexec 2>/dev/null
			mv /usr/bin/info /usr/bin/info.noexec 2>/dev/null
			mv /usr/bin/gtk-update-icon-cache /usr/bin/gtk-update-icon-cache.noexec 2>/dev/null
			mv /usr/bin/install-info /usr/bin/install-info.noexec 2>/dev/null

			let AVANCE+=1
			printf "$LANG_INSTALLINGPACKAGE" $P2 "$AVANCE / $NROPAQUETES"
			if [ "$AVANCE" = "$NROPAQUETES" ];then
				printf "AUTOCLEAN: YES"
			else
				printf "AUTOCLEAN: NO"
			fi
			cd $PKGDIR
# 			echo "$INSTALL $INSTALL_OPTIONS $P2"; echo;
			local UGETCHOST="i686"
			[ "x$PROC" = "xi486" ] && UGETCHOST="i486"

# 			if [ "x$(ps ax | grep 'chroot_stage.*sh' | grep -v grep | wc -l)" != "x0" ]; then
# 				verificarEmergeRealizado $P2
# 			fi

 			fixPortageDB 2>/dev/null
			
# 			echo "ACCEPT_KEYWORDS=\"~x86 x86\" CHOST=\"$UGETCHOST-pc-linux-gnu\" ARCH=\"x86\" USE=\"nptl\" AUTOCLEAN=\"no\" $INSTALL $INSTALL_OPTIONS $P2"
			if [ "$AVANCE" = "$NROPAQUETES" ];then
			    ACCEPT_KEYWORDS="~x86 x86" CHOST="$UGETCHOST-pc-linux-gnu" ARCH="x86" USE="nptl" AUTOCLEAN="yes" $INSTALL -v -q $INSTALL_OPTIONS $P2 2>/dev/null
			else
			    ACCEPT_KEYWORDS="~x86 x86" CHOST="$UGETCHOST-pc-linux-gnu" ARCH="x86" USE="nptl" AUTOCLEAN="no" $INSTALL -v -q $INSTALL_OPTIONS $P2 2>/dev/null
			fi
			sed -i "s/emerging by path is broken and may not always work/UTUTO XS GNU System Installer - UGet/" /usr/lib/portage/pym/_emerge/main.py
			sed -r -i '/emerging by path is broken and may not always work/s/^/#/' /usr/lib/portage/pym/_emerge/__init__.py
			sed -i -r 's/display_preserved_libs\([a-z]+\)[^:]/print " " # display_preserved_libs(varslib)/' /usr/lib/portage/pym/_emerge/__init__.py
 			fixPortageDB 2>/dev/null

			verificarEmergeRealizado $P2

			# Ejecuta acciones correctivas y de configuración que se encuentran en el script del kit
			P2=`echo $P | sed "s/http.*\///" | sed "s/.tbz2//"`
			comandosPostInstalacion "$P2"
		else
			echo "$P"
		fi
	done

	restaurarPortage

	mv /usr/bin/info.noexec /usr/bin/info
	mv /usr/bin/gtk-update-icon-cache.noexec /usr/bin/gtk-update-icon-cache
	mv /usr/bin/install-info.noexec /usr/bin/install-info
	
	echo "$LANG_FIXING..."
	fixUserGroups 2>/dev/null
	fixCFG00 2>/dev/null
	echo "$LANG_DONE"
	#echo "$LANG_REMOVINGOLDPACKAGES"
	#nice -n $NICELEVEL emerge -v -c -q 2>/dev/null
	#echo "$LANG_DONE"

}


###############################################################################
# Verfica librerias faltantes en el sistema y las instala. Luego optimiza mediante prelink
verificarLibrerias () {

	cp -a /sbin/ldconfig.noexec /sbin/ldconfig
	rm -f /sbin/ldconfig.noexec
	echo "$LANG_REMOVINGOLDPACKAGES"
	#nice -n $NICELEVEL emerge --clean -v -c -q 2>/dev/null
	#emerge --clean -c -v -q 2>/dev/null
	echo "$LANG_FIXING..."
	#emerge -v -q 2>/dev/null
	fixUserGroups 2>/dev/null
	fixCFG00 2>/dev/null
	echo "$LANG_PROCESSINGLIBRARIES"
	nice -n $NICELEVEL ldconfig
	echo "$LANG_DONE"
	
	ICONS=`nice -n $NICELEVEL ls -1 /usr/share/icons | grep -v ".png"`
	echo "$LANG_PROCESSINGICONS"
	for IC in `echo $ICONS`
	do
	    echo "* /usr/share/icons/$IC..."
	    nice -n $NICELEVEL /usr/bin/gtk-update-icon-cache -qf //usr/share/icons/$IC 2>/dev/null
	done
	echo "$LANG_DONE"
	echo "$LANG_PROCESSINGINFOFILES"
	ls -1 /usr/share/info/*.info.gz > /tmp/info-files
	while read infofile
        do
            echo "* $infofile"
	    nice -n $NICELEVEL /usr/bin/install-info $infofile --dir-file=/usr/share/info/dir
	done < /tmp/info-files
	rm -rf  /tmp/info-files
	
	###############################################################################
	# Busca librer�s faltantes y crea links a las versiones instaladas o las descarga directamente del repositorio
	if [ "x$(ps ax | grep check-ldd | grep -v grep | wc -l)" = "x0" ]; then
		if [ "x$ACTION" = "xverify" ]; then
			echo "$LANG_FIXING..."
			fixUserGroups
			fixCFG00
			emerge --clean -v -q 2>/dev/null
			echo "$LANG_DONE"
			#check-ldd $SERVER
		else
			echo "$LANG_FIXING..."
			fixUserGroups
			fixCFG00
			echo "$LANG_DONE"
			#check-ldd $SERVER &> /dev/null
		fi
	fi

	###############################################################################
	# Optimiza las librer�s instaladas o actualizadas
	if [ "x$PRELINK" = "x0" ]; then
		return
	elif [ "x$PRELINK" = "x-1" ]; then
		printf "$LANG_RUN_PRELINK" 
		printf "$LANG_CONFIRMCONTINUE"
		CONFIRMA=no
		read -t $((TOUT/2)) CONFIRMA
		if [ "x$CONFIRMA" != "xn" -o "x$CONFIRMA" = "xno" -o "x$CONFIRMA" = "xNO" -o "x$CONFIRMA" = "xN" ]; then
			return
		fi
	fi
	if [ "x$(ps ax | grep prelink | grep -v grep | wc -l)" = "x0" ]; then
		if [ "x$ACTION" = "xverify" ]; then
			prelink -amR
		else
			prelink -amR  &> /dev/null
		fi
	fi

	wall $LANG_CHECKLDCOMPLETE

}

registrarAcciones () {
	mkdir -p $LOGSDIR
	echo "`date '+%F %R'` $1 $2 $3 $4" >> $LOGSDIR/ututo-get.history
}

###############################################################################
# Funcion: updateUtutoGet
#
updateUtutoGet()
{

	echo -e "$LANG_UPDATEINPROGRESS"

	# Actualizar eclass
	echo -e "$LANG_UPDATING_ECLASS"
	[ ! -d $PKGDIR ] && mkdir -p $PKGDIR
	cd $PKGDIR
	rm -f eclass.tar.bz2
	$GET $PROTOCOL://$SERVER/utiles/eclass.tar.bz2
	mkdir -p $PORTDIR/eclass &>/dev/null
	mkdir -p $REPOSDIR/scripts

	if [ -f $PKGDIR/eclass.tar.bz2 ]; then
		tar $TAR_OPTIONS eclass.tar.bz2 -C $PORTDIR/eclass/ 2>&1 | sed 's/.*/./g' | tr -d '\n\r'
	else
		echo -e "$BEEP $WHITE"
		echo "$LANG_UPDATING_ECLASS_ERROR"
		echo -e "$NO_COLOUR"
		exit 1;
	fi

	echo -e "$LANG_UPDATING_PACKAGESLIST"
	mkdir $PKGDIR &> /dev/null
	cd $PKGDIR
	[ -f $DISPONIBLES_FILE ] && rm -f $DISPONIBLES_FILE
	$GET $DISPONIBLES_URL/$DISPONIBLES_FILE

	if [ -f $PKGDIR/$DISPONIBLES_FILE ]; then
		rm -R $REPOSDIR/scripts
		mkdir -p $REPOSDIR/scripts
		[[ "x$DISPONIBLES_FILE" = "x$REPOSITORIO.tar.bz2" ]] && tar -xvjpf $PKGDIR/$DISPONIBLES_FILE -C $REPOSDIR/scripts  2>&1 | sed 's/.*/./g' | tr -d '\n\r'
		[[ "x$DISPONIBLES_FILE" = "x$REPOSITORIO.7z" ]] && 7zr e -y -o$REPOSDIR/scripts $PKGDIR/$DISPONIBLES_FILE  2>&1 | sed 's/.*/./g' | tr -d '\n\r'
		nscripts=$(ls -1 $REPOSDIR/scripts/ | wc -l)
	fi

	cd /tmp
	rm -f gnome-splash.png
	rm -f ututo-emergence.png
	$GET $PROTOCOL://$SERVER/utiles/gnome-splash.png &>/dev/null
	$GET $PROTOCOL://$SERVER/utiles/ututo-emergence.png &>/dev/null
# 	$GET $PROTOCOL://$SERVER/utiles/actualiza-menu-disponibles &>/dev/null
# 	cp /tmp/actualiza-menu-disponibles /admin
	rm -f /tmp/actualiza-menu-disponibles
	cp /tmp/gnome-splash.png /usr/share/pixmaps/splash &>/dev/null
	cp /tmp/gnome-splash.png /usr/share/pixmaps/splash/gentoo-splash.png &>/dev/null
	cp /tmp/ututo-emergence.png /usr/share/gdm/themes/gentoo-emergence &>/dev/null
	cp /tmp/ututo-emergence.png /usr/share/gdm/themes/ututo-emergence &>/dev/null
	cp /tmp/ututo-emergence.png /usr/share/gdm/themes/ututo-emergence/gentoo-emergence.png &>/dev/null
	clear
	echo "$LANG_OPTIMIZING_LIBRARIES"
# 	$GET $PROTOCOL://$SERVER/utiles/actualiza-menu-disponibles &>/dev/null
# 	cp /tmp/actualiza-menu-disponibles /admin
	rm -f /tmp/actualiza-menu-disponibles
	rm -rf /var/tmp/portage
	mkdir /var/tmp/portage
# 	cd /admin
# 	rm -f /admin/seguridad-usuarios
# 	$GET $PROTOCOL://$SERVER/utiles/seguridad-usuarios &>/dev/null
# 	chmod 555 /admin/seguridad-usuarios


	rm -rf /var/cache/edb ; emerge -v -q 2>/dev/nul
	
# 	(for f in $(ls -1 $REPOSDIR/scripts/); do 
# 		CAT=$(head -n 5 $REPOSDIR/scripts/$f | grep CATEGORY | sed -r "s/^.*\" (.*)\"/\1/g");
# 		echo 
# 		echo -n . >&2;
# 	done) | sort -u > $REPOSDIR/categories.lst
# 	echo

	cd $VERSDIR
	$GET $DISPONIBLES_URL/$REPOSITORIO.lastversion
	mv $VERSDIR/$REPOSITORIO.lastversion $VERSDIR/$REPOSITORIO.lastupdate
	if [ "x$DEBUG" = "x1" ]; then
		mv $REPOSDIR/$DISPONIBLES_FILE "$REPOSDIR/$DISPONIBLES_FILE-$(head -n 1 $VERSDIR/$REPOSITORIO.lastupdate)"
	fi


	printf "$LANG_NUM_PACKAGES_AVAILABLE" "$nscripts"
	echo -e "$LANG_DONE""\n"
}

###############################################################################
# Funcion: updatePortage
#
updatePortage() {
	
	echo -e "$LANG_UPDATINGPORTAGE"
	mkdir -p /usr/portage/packages/All
	cd /usr/portage/packages/All
	[[ -f $PORTAGE_FILE ]] && rm $PORTAGE_FILE
	$GET $PORTAGE_URL/$PORTAGE_FILE
	if [ -f $PORTAGE_FILE ]; then
		
		mkdir -p /usr/portage
		for d in $(find /usr/portage/* -type d -a ! -wholename "/usr/portage/packages" -a ! -wholename "/usr/portage/packages/All" -a ! -wholename "/usr/portage/distfiles*")
		do
			rm -rf $d
		done
		rm /usr/portage/*
		rm /usr/portage/packages/*
		
		7z x -so -bd $PORTAGE_FILE 2>/dev/null | tar xvf - -C /usr/portage/ | grep *ebuild
		rm -f /etc/make.profile
		ln -s /usr/portage/profiles/default-linux/x86 /etc/make.profile
		emerge -v -q 2>/dev/null

	fi	
	DD=`pwd`
	cd /etc/
	rm make.profile
	ln -s ../usr/portage/profiles/default/linux/x86/10.0 make.profile
	cd $DD
	echo
	echo -e "$LANG_DONE""\n"
	return
}

###############################################################################
# Verifica si es necesario actualizar la base de paquetes y/o ututo-get
verificarActualizacionesDisponibles () {

	##########################################################
	# Verifica si es necesario actualizar ututo-get
	printf "$LANG_CHECK_VERSION_UTUTOGETSH" ${UTUTOGET_URL//*\//}
	mkdir -p $VERSDIR
	cd $VERSDIR
	[ -f ututo-get.lastversion ] && rm -f ututo-get.lastversion
	$GET --quiet $UTUTOGET_URL/ututo-get.lastversion > /dev/null
	if [ -f $VERSDIR/ututo-get.lastversion ]; then
		UTUTOGETSHLASTVERSION="`head -n 1 $VERSDIR/ututo-get.lastversion 2> /dev/null`" 
		UTUTOGETSHLASTUPDATE="`head -n 1 $VERSDIR/ututo-get.lastupdate 2> /dev/null`" 
		if [ "$UTUTOGETSHLASTVERSION" != "$UTUTOGETSHLASTUPDATE" ]; then
			echo " $LANG_DOWNLOADING"
			NUEVOUTUTOGET="true"
		else
			echo " $LANG_DONE"
		fi
	else 
		echo " $LANG_FAILED"
		
		NUEVOUTUTOGET="force"
		
	fi


	if [ "x$NUEVOUTUTOGET" = "xtrue" -o "x$NUEVOUTUTOGET" = "xforce" ]; then
		autoupgradeUtutoGet --$NUEVOUTUTOGET
		if [ "x$PARAM2" != "x" ];then
		    if [ "x$PARAM1" != "x" ];then
			echo "Relaunching new version..."
			/usr/sbin/uget $PARAM1 $PARAM2 &
			exit;exit;exit;
		    fi
		else
		    if [ "x$PARAM1" != "x" ];then
			echo "Relaunching new version..."
			/usr/sbin/uget $PARAM1 &
			exit;exit;exit;
		    fi
		fi
	fi

	##########################################################
	# Verifica si es necesario actualizar la base de paquetes
	if [ "$ACTION" != "update" -a "$ACTION" != "portage" ]; then
		echo -n "$LANG_CHECK_VERSION_REPOSITORY"
		cd $VERSDIR
		[ -f $REPOSITORIO.lastversion ] && rm -f $VERSDIR/$REPOSITORIO.lastversion
		$GET --quiet $DISPONIBLES_URL/$REPOSITORIO.lastversion > /dev/null
		if [ -f $VERSDIR/$REPOSITORIO.lastversion ]; then
			DISPONIBLESLASTVERSION="`head -n 1 $VERSDIR/$REPOSITORIO.lastversion 2> /dev/null`" 
			DISPONIBLESLASTUPDATE="`head -n 1 $VERSDIR/$REPOSITORIO.lastupdate 2> /dev/null`" 
			if [ "$DISPONIBLESLASTVERSION" != "$DISPONIBLESLASTUPDATE" ]; then
				echo " $LANG_DOWNLOADING"
				for i in 1 2 3 4 5; do
					echo -en "$BEEP$i "; sleep 1s;
				done
				updateUtutoGet
			else
				echo " $LANG_DONE"
			fi
		else 
			echo " $LANG_FAILED"
		fi
	fi

	restaurarPortage

	sed -r -i '/emerging by path is broken and may not always work/s/^/#/' /usr/lib/portage/pym/_emerge/__init__.py
	sed -i -r 's/display_preserved_libs\([a-z]+\)[^:]/print " " # display_preserved_libs(varslib)/' /usr/lib/portage/pym/_emerge/__init__.py

	##############################################################################
	# check-ldd is a critical part of the system, if we cannot download and update
	# this tool we should not go ahead with installation
# 	echo -n "$LANG_UPDATING_CHECKLDD"
# 	cd /; rm -f /check-ldd 2>/dev/null
# 	$GET -q $CHECKLDD_URL
# 	if [ -f /check-ldd ]; then
# 		sed -i "s/nice -n .[0-9]* //g" /check-ldd
# 		mv /check-ldd /usr/bin/check-ldd
# 		chmod a+x /usr/bin/check-ldd
# 		chown root:root /usr/bin/check-ldd
# 		echo " $LANG_DONE"
# 	else
# 		echo " $LANG_FAILED"
# 		printf "$LANG_FAILED_CHECKLDDDOWNLOAD" $CHECKLDD_URL
# 		exit 1	
# 	fi

}

###############################################################################
# Actualiza los principales paquetes del sistema
distUpgrade () {

	[[ ! -d $ugettmpdir ]] && mkdir -p $ugettmpdir
	cd $ugettmpdir
	FILE="$param"
	echo "executing... $FILE"
	$GETPKG --quiet $UTUTOGET_URL/$FILE.sh
	eInfo "${LANG_UPDATEINPROGRESS}"
	eInfo "${LANG_INSTALLINGINSECONDS}\n"
	chmod 755 $ugettmpdir/$FILE.sh
	chown root.root $ugettmpdir/$FILE.sh
	beepNSecs 9
	nice -n -19 bash -x -c "$ugettmpdir/$FILE.sh &"

}

###############################################################################
# Instala parches en el sistema
patchUpgrade () {

	[[ ! -d $ugettmpdir ]] && mkdir -p $ugettmpdir
	cd $ugettmpdir
	$GETPKG --quiet $UTUTOGET_URL/$1.sh
	eInfo "${LANG_UPDATEINPROGRESS}"
	eInfo "${LANG_INSTALLINGINSECONDS}\n"
	chmod 755 $ugettmpdir/$1.sh
	chown root.root $ugettmpdir/$1.sh
	beepNSecs 9
	nice -n -19 bash -x -c "$ugettmpdir/$1.sh &"

}

###############################################################################
# Verifica si es necesario actualizar la base de paquetes y/o ututo-get
verificarActualizacionesDisponibles

if [ "x$1" = "xautoupgradeuget" ]; then
	exit
fi

UTUTORELEASE=$(egrep -o "UTUTO XS [0-9]{4}" /etc/ututo-release | egrep -o "[0-9]{4}")
TESTGLIBC=`ls -1 /var/db/pkg/sys-libs/ | grep glibc-2.5`
if [[ "$UTUTORELEASE" != "" && $UTUTORELEASE -lt 2007 && "$TESTGLIBC" = "" ]];then
    if [ "$2" != "glibc" ] && [ "$2" != "xorg" ] && [ "$1" != "update" ];then
        echo " "
        echo " "
        echo " "
        echo " "
        echo " "
        echo -e "$LANG_IMPORTANT_NOTICE_GLIBC"
        echo " "
        echo " "
        echo " "
        echo " "
		for i in 1 2 3 4 5 6 7 8 9; do
			echo -en "$BEEP$i "; sleep 1s;
		done
        exit 1
    fi
fi


if [ "x$1" = "xverify" ]; then
	verificarLibrerias
	fixUserGroups
	fixCFG00
	kbuildsycoca4 2>/dev/null
	exit 0
fi

if [ "x$1" = "xinstallpkg" ]; then
    mkdir /usr/portage/packages/All 2>/dev/null
    cd /usr/portage/packages/All 2>/dev/null
    if [ "`echo $2 | grep .deb`" != "" ];then
	TYPEBIN="deb"
    elif [ "`echo $2 | grep .rpm`" != "" ];then
	TYPEBIN="rpm"
    elif [ "`echo $2 | grep .txz`" != "" ];then
	TYPEBIN="txz"
    elif [ "`echo $2 | grep .tbz2`" != "" ];then
	TYPEBIN="tbz2"
    else
	echo "$LANG_BINERROR"
	exit 0
    fi
    echo "$LANG_INSTALLING $TYPEBIN $2...."
    if [ "$TYPEBIN" = "deb" ];then
	DIRTMP="debinstall"
	if [ -e /var/db/pkgbin/sys-$DIRTMP/`echo $2 | sed "s/.$TYPEBIN//"`/`echo $2 | sed "s/.$TYPEBIN//"`.ebuild ];then
	    echo "$LANG_PACKAGE $LANG_INSTALLED"
	    echo "$LANG_DONE"
	    exit 0
	fi 
	mkdir /tmp/$DIRTMP 2>/dev/null
	cp -a $2 /tmp/$DIRTMP 2>/dev/null
	DIRPWD=`pwd`
	cd /tmp/$DIRTMP 2>/dev/null
	dpkg -x $2 . 2>/dev/null
	rm -rf $2 2>/dev/null
	mkdir /var/db/pkgbin 2>/dev/null
	mkdir /var/db/pkgbin/sys-$DIRTMP 2>/dev/null
	mkdir /var/db/pkgbin/sys-$DIRTMP/`echo $2 | sed "s/.$TYPEBIN//"` 2>/dev/null
	find | sed "s/./XXXX/" | sed "s/XXXX\///" | grep -v "XXXX" > /var/db/pkgbin/sys-$DIRTMP/`echo $2 | sed "s/.$TYPEBIN//"`/CONTENTS 2>/dev/null
	touch /var/db/pkgbin/sys-$DIRTMP/`echo $2 | sed "s/.$TYPEBIN//"`/`echo $2 | sed "s/.$TYPEBIN//"`.ebuild 2>/dev/null
	cp -aR . /
	rm -rf /tmp/$DIRTMP
    fi
    if [ "$TYPEBIN" = "rpm" ];then
	DIRTMP="rpminstall"
	if [ -e /var/db/pkgbin/sys-$DIRTMP/`echo $2 | sed "s/.$TYPEBIN//"`/`echo $2 | sed "s/.$TYPEBIN//"`.ebuild ];then
	    echo "$LANG_PACKAGE $LANG_INSTALLED"
	    echo "$LANG_DONE"
	    exit 0
	fi 
	mkdir /tmp/$DIRTMP 2>/dev/null
	cp -a $2 /tmp/$DIRTMP 2>/dev/null
	DIRPWD=`pwd`
	cd /tmp/$DIRTMP 2>/dev/null
	mkdir rpminside 2>/dev/null
	cd rpminside
	rpm2cpio ../$2 | cpio -i --make-directories
	cd ..
	rm -rf $2 2>/dev/null
	mkdir /var/db/pkgbin 2>/dev/null
	mkdir /var/db/pkgbin/sys-$DIRTMP 2>/dev/null
	mkdir /var/db/pkgbin/sys-$DIRTMP/`echo $2 | sed "s/.$TYPEBIN//"` 2>/dev/null
	cd rpminside
	find | sed "s/./XXXX/" | sed "s/XXXX\///" | grep -v "XXXX" > /var/db/pkgbin/sys-$DIRTMP/`echo $2 | sed "s/.$TYPEBIN//"`/CONTENTS 2>/dev/null
	touch /var/db/pkgbin/sys-$DIRTMP/`echo $2 | sed "s/.$TYPEBIN//"`/`echo $2 | sed "s/.$TYPEBIN//"`.ebuild 2>/dev/null
	cp -aR . /
	cd ..
	rm -rf /tmp/$DIRTMP
    fi
    if [ "$TYPEBIN" = "txz" ];then
	DIRTMP="txzinstall"
	if [ -e /var/db/pkgbin/sys-$DIRTMP/`echo $2 | sed "s/.$TYPEBIN//"`/`echo $2 | sed "s/.$TYPEBIN//"`.ebuild ];then
	    echo "$LANG_PACKAGE $LANG_INSTALLED"
	    echo "$LANG_DONE"
	    exit 0
	fi 
	mkdir /tmp/$DIRTMP 2>/dev/null
	cp -a $2 /tmp/$DIRTMP 2>/dev/null
	DIRPWD=`pwd`
	cd /tmp/$DIRTMP 2>/dev/null
	tar -Jxvf $2 &>/dev/null
	rm -rf $2 2>/dev/null
	rm -rf install 2>/dev/null
	mkdir /var/db/pkgbin 2>/dev/null
	mkdir /var/db/pkgbin/sys-$DIRTMP 2>/dev/null
	mkdir /var/db/pkgbin/sys-$DIRTMP/`echo $2 | sed "s/.$TYPEBIN//"` 2>/dev/null
	find | sed "s/./XXXX/" | sed "s/XXXX\///" | grep -v "XXXX" > /var/db/pkgbin/sys-$DIRTMP/`echo $2 | sed "s/.$TYPEBIN//"`/CONTENTS 2>/dev/null
	touch /var/db/pkgbin/sys-$DIRTMP/`echo $2 | sed "s/.$TYPEBIN//"`/`echo $2 | sed "s/.$TYPEBIN//"`.ebuild 2>/dev/null
	cp -aR . /
	rm -rf /tmp/$DIRTMP
    fi
    if [ "$TYPEBIN" = "tbz2" ];then
	echo "$LANG_INSTALLING"
	ACCEPT_KEYWORDS="~x86 x86" $INSTALL -v -q $INSTALL_OPTIONS $2 2>/dev/null
	echo "$LANG_FIXING..."
	fixUserGroups
	fixCFG00
    fi
    kbuildsycoca4 2>/dev/null
    echo "$LANG_DONE"
    exit 0
fi

if [ "x$1" = "xdevelkit" ]; then
	if [ "x$2" = "x" ]; then
	    SYSTEMNAME=`head /system.name -n 1`
	    SKELTYPE="$SYSTEMNAME"
	else
	    SKELTYPE=".$2"
	fi
	cd /tmp
	echo "$LANG_IMPORTKEYS..."
	wget $GET_OPTIONS http://packages.ututo.org/utiles/skels/clave-ututo-1.asc
	wget $GET_OPTIONS http://packages.ututo.org/utiles/skels/clave-ututo-2.asc
	gpg --import clave-ututo-1.asc
	gpg --import clave-ututo-2.asc
	rm -rf clave-ututo-1.asc
	rm -rf clave-ututo-2.asc
	echo "$LANG_DOWNLOADING DevelKit $SKELTYPE"
	wget $GET_OPTIONS $PROTOCOL://$SERVER/utiles/kit/kit$SKELTYPE.tar.bz2
	wget $GET_OPTIONS $PROTOCOL://$SERVER/utiles/kit/kit$SKELTYPE.tar.bz2.sig1
	LANGUAGE=\"us\" gpg --verify kit$SYSTEMNAME.tar.bz2.sig1 kit$SYSTEMNAME.tar.bz2 2> /SIGN1
	SIGN=`cat /SIGN1`
	ANASIG=""
	ANASIG=`echo $SIGN | grep "Good signature"`
	if [ "$ANASIG" != "" ];then
	    sleep 0
	else
	    echo "$LANG_GPG_ERROR DevelKit $SKELTYPE"
	    exit ; exit ; exit
	fi
	echo "$LANG_INSTALLING"
	if [ -e kit$SKELTYPE.tar.bz2 ]; then
	    tar -xvjpf kit$SKELTYPE.tar.bz2 -C /
	else
	    echo "$LANG_NOTFOUND DevelKit $SKELTYPE"
	    exit ; exit ; exit
	fi
	echo "$LANG_FIXING..."
	fixUserGroups
	fixCFG00
	echo "$LANG_DONE"
	exit 0
fi

if [ "x$1" = "xskel" ]; then
	if [ "x$2" = "x" ]; then
	    SYSTEMNAME=`head /system.name -n 1`
	    SKELTYPE="$SYSTEMNAME"
	else
	    SKELTYPE=".$2"
	fi
	cd /tmp
	rm -rf skel3$SKELTYPE.lastversion
	wget -c -q $GET_OPTIONS $PROTOCOL://$SERVER/utiles/skels/skel3$SKELTYPE.lastversion
	VERSSA=`cat /etc/uget/version/skel3$SKELTYPE.installed`
	VERSSN=`cat skel3$SKELTYPE.lastversion`
	if [ "$VERSSA" != "$VERSSN"  ];then
	    rm -rf skel3$SKELTYPE.tar.bz2
	    rm -rf skel3$SKELTYPE.tar.bz2.sig1
	    rm -rf skel3$SKELTYPE.tar.xz
	    rm -rf skel3$SKELTYPE.tar.xz.sig1
	    echo "$LANG_IMPORTKEYS..."
	    wget $GET_OPTIONS http://packages.ututo.org/utiles/skels/clave-ututo-1.asc
	    wget $GET_OPTIONS http://packages.ututo.org/utiles/skels/clave-ututo-2.asc
	    gpg --import clave-ututo-1.asc
	    gpg --import clave-ututo-2.asc
	    rm -rf clave-ututo-1.asc
	    rm -rf clave-ututo-2.asc
	    echo "-----------------------------------------------------------------"
	    echo "-----------------------------------------------------------------"
	    echo "$LANG_DOWNSKEL... $SKELTYPE Version $VERSSN"
	    echo "-----------------------------------------------------------------"
	    echo "-----------------------------------------------------------------"
	    wget $GET_OPTIONS $PROTOCOL://$SERVER/utiles/skels/skel3$SKELTYPE.tar.xz
	    wget $GET_OPTIONS $PROTOCOL://$SERVER/utiles/skels/skel3$SKELTYPE.tar.xz.sig1
	    LANGUAGE=\"us\" gpg --verify skel3$SYSTEMNAME.tar.xz.sig1 skel3$SYSTEMNAME.tar.xz 2> /SIGN1
	    SIGN=`cat /SIGN1`
	    rm -rf /SIGN1
	    ANASIG=""
	    ANASIG=`echo $SIGN | grep "Good signature"`
	    if [ "$ANASIG" != "" ];then
		sleep 0
	    else
		echo "$LANG_GPG_ERROR $SKELTYPE"
		exit ; exit ; exit
	    fi
	    echo "$LANG_INSTALLING"
	    if [ -e skel3$SKELTYPE.tar.xz ]; then
		rm -rf /etc/skel.skel
		rm -rf /etc/skel
		rm -rf /usr/share/xsessions/gnome*
		rm -rf /usr/share/xsessions/KDE-4*
		rm -rf /usr/share/xsessions/openbox-*
		rm -rf /etc/runlevels/default/cupsd
		rm -rf /etc/runlevels/default/ddclient
		rm -rf /etc/runlevels/default/detect-new-partitions
		rm -rf /etc/runlevels/default/vixie-cron
		rm -rf /etc/runlevels/default/openerp-web
		rm -rf /etc/runlevels/default/psad
		rm -rf /etc/runlevels/default/nscd
		#tar -xvjpf skel3$SKELTYPE.tar.bz2 -C /
		tar -Jxvf skel3$SKELTYPE.tar.xz -C /
		mv /etc/skel.skel /etc/skel
		mv skel3$SKELTYPE.lastversion /etc/uget/version/skel3$SKELTYPE.installed
		rm -rf /localdns 2>/dev/null
		rm -rf /opennic 2>/dev/null
		rm -rf /etc/resolv.conf 2>/dev/null
		kbuildsycoca4 2>/dev/null
	    else
		echo "$LANG_PROFILE $SKELTYPE $LANG_NOTFOUND"
		exit ; exit ; exit
	    fi
	else
	    echo "--------------------------------------------------------"
	    echo "--------------------------------------------------------"
	    echo "$LANG_SKELPREVINST (Version: $VERSSN)"
	    echo "--------------------------------------------------------"
	    echo "--------------------------------------------------------"
	fi
	echo "$LANG_FIXING..."
	fixUserGroups
	fixCFG00
	echo "$LANG_DONE"
	exit 0
fi

if [ "x$1" = "xskellocal" ]; then
	if [ -e $2 ] && [ "$2" != "" ]; then
		echo "$LANG_INSTALLING"
		rm -rf /etc/skel.skel
		rm -rf /etc/skel
		rm -rf /usr/share/xsessions/gnome*
		rm -rf /usr/share/xsessions/KDE-4*
		rm -rf /usr/share/xsessions/openbox-*
		rm -rf /etc/runlevels/default/cupsd
		rm -rf /etc/runlevels/default/ddclient
		rm -rf /etc/runlevels/default/detect-new-partitions
		rm -rf /etc/runlevels/default/vixie-cron
		rm -rf /etc/runlevels/default/openerp-web
		rm -rf /etc/runlevels/default/psad
		rm -rf /etc/runlevels/default/nscd
		#tar -xvjpf $2 -C /
		tar -Jxvf $2 -C /
		mv /etc/skel.skel /etc/skel
		rm -rf /localdns 2>/dev/null
		rm -rf /opennic 2>/dev/null
		rm -rf /etc/resolv.conf 2>/dev/null
		kbuildsycoca4 2>/dev/null
	else
		echo "$LANG_PROFILE $2 $LANG_NOTFOUND"
		exit ; exit ; exit
	fi
	echo "$LANG_FIXING..."
	fixUserGroups
	fixCFG00
	echo "$LANG_DONE"
	exit 0
fi

if [ "x$1" = "xskelinstall" ]; then
	if [ "x$2" = "x" ]; then
	    SYSTEMNAME=`head /system.name -n 1`
	    SKELTYPE="$SYSTEMNAME"
	else
	    SKELTYPE=".$2"
	fi
	cd /tmp
	rm -rf skel3$SKELTYPE.lastversion
	wget -c -q $GET_OPTIONS $PROTOCOL://$SERVER/utiles/skels/skel3$SKELTYPE.lastversion
	VERSSA=`cat /etc/uget/version/skel3$SKELTYPE.installed`
	VERSSN=`cat skel3$SKELTYPE.lastversion`
	if [ "$VERSSA" != "$VERSSN"  ];then
	    rm -rf skel3$SKELTYPE.tar.bz2
	    rm -rf skel3$SKELTYPE.tar.bz2.sig1
	    rm -rf skel3$SKELTYPE.tar.xz
	    rm -rf skel3$SKELTYPE.tar.xz.sig1
	    echo "$LANG_IMPORTKEYS..."
	    wget $GET_OPTIONS http://packages.ututo.org/utiles/skels/clave-ututo-1.asc
	    wget $GET_OPTIONS http://packages.ututo.org/utiles/skels/clave-ututo-2.asc
	    gpg --import clave-ututo-1.asc
	    gpg --import clave-ututo-2.asc
	    rm -rf clave-ututo-1.asc
	    rm -rf clave-ututo-2.asc
	    echo "-----------------------------------------------------------------"
	    echo "-----------------------------------------------------------------"
	    echo "$LANG_DOWNSKEL... $SKELTYPE Version $VERSSN"
	    echo "-----------------------------------------------------------------"
	    echo "-----------------------------------------------------------------"
	    wget $GET_OPTIONS $PROTOCOL://$SERVER/utiles/skels/skel3$SKELTYPE.tar.xz
	    wget $GET_OPTIONS $PROTOCOL://$SERVER/utiles/skels/skel3$SKELTYPE.tar.xz.sig1
	    LANGUAGE=\"us\" gpg --verify skel3$SYSTEMNAME.tar.xz.sig1 skel3$SYSTEMNAME.tar.xz 2> /SIGN1
	    SIGN=`cat /SIGN1`
	    rm -rf /SIGN1
	    ANASIG=""
	    ANASIG=`echo $SIGN | grep "Good signature"`
	    if [ "$ANASIG" != "" ];then
		sleep 0
	    else
		echo "$LANG_GPG_ERROR $SKELTYPE"
		exit ; exit ; exit
	    fi
	    echo "$LANG_INSTALLING"
	    if [ -e skel3$SKELTYPE.tar.xz ]; then
		rm -rf /etc/skel.skel
		rm -rf /etc/skel
		rm -rf /usr/share/xsessions/gnome*
		rm -rf /usr/share/xsessions/KDE-4*
		rm -rf /usr/share/xsessions/openbox-*
		#tar -xvjpf skel3$SKELTYPE.tar.bz2 -C /
		tar -Jxvf skel3$SKELTYPE.tar.xz -C /
		mv /etc/skel.skel /etc/skel
		mv /etc/X11/xorg.conf.skel /etc/X11/xorg.conf
		mv /etc/conf.d/local.skel /etc/conf.d/local
		mv /etc/conf.d/xdm.skel /etc/conf.d/xdm
		mv /etc/inittab.skel /etc/inittab
		rm -rf /etc/runlevels
		mv /etc/runlevels.skel /etc/runlevels
		mv /var/spool/cron/crontabs/root.skel /var/spool/cron/crontabs/root
		#fixuser ututo
		fixuser root
		ls -1 /home/* | grep ":" | grep -v "usuario" | grep -v "ntp"  | grep -v "public" | grep -v "p2p" | sed "s/://" | cut -d "/" -f 3 > /usuarios
		while read USER
		do
		    fixuser $USER
		done < /usuarios
		rm -rf /usuarios
		mv skel3$SKELTYPE.lastversion /etc/uget/version/skel3$SKELTYPE.installed
		rm -rf /localdns 2>/dev/null
		rm -rf /opennic 2>/dev/null
		rm -rf /etc/resolv.conf 2>/dev/null
		kbuildsycoca4 2>/dev/null
	    else
		echo "$LANG_PROFILE $SKELTIPE $LANG_NOTFOUND"
		exit ; exit ; exit
	    fi
	else
	    echo "--------------------------------------------------------"
	    echo "--------------------------------------------------------"
	    echo "$LANG_SKELPREVINST (Version: $VERSSN)"
	    echo "--------------------------------------------------------"
	    echo "--------------------------------------------------------"
	fi
	echo "$LANG_FIXING..."
	fixUserGroups
	fixCFG00
	echo "$LANG_DONE"
	exit 0
fi

if [ "x$1" = "xskelinstalllocal" ]; then
	if [ -e $2 ] && [ "$2" != "" ]; then
		echo "$LANG_INSTALLING"
		rm -rf /etc/skel.skel
		rm -rf /etc/skel
		rm -rf /usr/share/xsessions/gnome*
		rm -rf /usr/share/xsessions/KDE-4*
		rm -rf /usr/share/xsessions/openbox-*
		#tar -xvjpf $2 -C /
		tar -Jxvf $2 -C /
		mv /etc/skel.skel /etc/skel
		mv /etc/X11/xorg.conf.skel /etc/X11/xorg.conf
		mv /etc/conf.d/local.skel /etc/conf.d/local
		mv /etc/conf.d/xdm.skel /etc/conf.d/xdm
		mv /etc/inittab.skel /etc/inittab
		rm -rf /etc/runlevels
		mv /etc/runlevels.skel /etc/runlevels
		mv /var/spool/cron/crontabs/root.skel /var/spool/cron/crontabs/root
		#fixuser ututo
		fixuser root
		ls -1 /home/* | grep ":" | grep -v "usuario" | grep -v "ntp" | grep -v "public" | grep -v "p2p" | sed "s/://" | cut -d "/" -f 3 > /usuarios
		while read USER
		do
		    fixuser $USER
		done < /usuarios
		rm -rf /usuarios
		rm -rf /localdns 2>/dev/null
		rm -rf /opennic 2>/dev/null
		rm -rf /etc/resolv.conf 2>/dev/null
		kbuildsycoca4 2>/dev/null
	else
		echo "$LANG_PROFILE $2 $LANG_NOTFOUND"
		exit ; exit ; exit
	fi
	echo "$LANG_FIXING..."
	fixUserGroups
	fixCFG00
	echo "$LANG_DONE"
	exit 0
fi

if [ "x$1" = "xchangelog" ]; then
	if [ "x$2" = "x" ]; then
	    SYSTEMNAME=`head /system.name -n 1`
	    SYSTEMID="$SYSTEMNAME"
	else
	    SYSTEMID=".$2"
	fi
	cd /tmp
	rm -rf /tmp/ChangelogXS$SYSTEMID.txt
	echo "$LANG_DOWNLOADING..."
	wget $GET_OPTIONS $PROTOCOL://$SERVER/utiles/skels/ChangelogXS$SYSTEMID.txt
	mcedit /tmp/ChangelogXS.txt
	rm -rf /tmp/ChangelogXS.txt
	exit 0
fi

if [ "x$1" = "xcpu" ]; then
	echo "-------------------------------------------------------------------------------------------"
	top -n 1 | head -n 6
	echo "-------------------------------------------------------------------------------------------"
	echo -n "Proc: "`select_cpu-type.sh -m`
	echo " - Opt: "`select_cpu-type.sh -u`
	echo "-------------------------------------------------------------------------------------------"
	df -h
	echo "-------------------------------------------------------------------------------------------"
	vmstat -a
	echo "-------------------------------------------------------------------------------------------"
	vmstat -d
	echo "-------------------------------------------------------------------------------------------"
	exit 0
fi

if [ "x$1" = "xsearch" ]; then
    echo "$LANG_SEARCHING..."
    ls -1v $REPOSDIR/scripts/*.sh | sed "s/\/var\/db\/uget\/scripts\///g" | sed "s/\.sh//g" > /tmp/search-ututo.txt
    MOSTRAR=""
    while read PQ
    do
	MOSTRAR=`cat $REPOSDIR/scripts/$PQ.sh | grep "DESCRIPTION=" | tr [:upper:] [:lower:] | grep "$2"`
	if [ "$MOSTRAR" = "" ];then
	    MOSTRAR=`ls -1v $REPOSDIR/scripts/$PQ.sh | tr [:upper:] [:lower:] | grep "$2" | grep -v grep`
	fi
	EXISTE=`find /var/db/pkg -type f -name '*.ebuild' -print | sed -e "s/.ebuild//" | grep "$PQ" | cut -d "/" -f 7`
	if [ "$EXISTE" = "" ];then
	    FLAG="      "
	else
	    FLAG="[INST]"
	fi
	if [ "$MOSTRAR" != "" ];then
	    MOSTRAR=`cat $REPOSDIR/scripts/$PQ.sh | grep "DESCRIPTION=" | grep "$2"`
	    MOSTRAR=`echo $MOSTRAR | sed "s/DESCRIPTION=//g" | sed "s/\"//g" `
	    echo "$PQ - $FLAG $MOSTRAR"
	fi
    done < /tmp/search-ututo.txt
    rm -rf /tmp/search-ututo.txt
fi

if [ "x$1" = "xcategory" ]; then
    echo "$LANG_SEARCHING..."
    ls -1v $REPOSDIR/scripts/*.sh | sed "s/\/var\/db\/uget\/scripts\///g" | sed "s/\.sh//g" > /tmp/search-ututo.txt
    MOSTRAR=""
    while read PQ
    do
	MOSTRAR=`cat $REPOSDIR/scripts/$PQ.sh | grep "CATEGORY=" | grep "$2"`
	if [ "$MOSTRAR" != "" ];then
	    MOSTRAR=`echo $MOSTRAR | sed "s/CATEGORY=//g" | sed "s/ //g" | sed "s/\"//g" `
	    EXISTE=`find /var/db/pkg -type f -name '*.ebuild' -print | sed -e "s/.ebuild//" | grep "$PQ" | cut -d "/" -f 7`
	    if [ "$EXISTE" = "" ];then
		FLAG="      "
	    else
		FLAG="[INST]"
	    fi
	    echo "$MOSTRAR $FLAG: $PQ"
	fi
    done < /tmp/search-ututo.txt
    rm -rf /tmp/search-ututo.txt
fi

###############################################################################
# Simplemente muestra DESCRIPTION y LICENSE del paquete tomado del emerge
if [ "x$1" = "xinfo" ]; then
	echo "$LANG_SEARCHING..."
	#ls -1v $REPOSDIR/scripts | grep "$2" | grep -v grep | tail -n 1 > /tmp/einfo.ututo-get
	ls -1v $REPOSDIR/scripts | grep "$2" | grep -v grep > /tmp/einfo.ututo-get
	dbpkg=`nice -n $NICELEVEL find /var/db/pkg -type f -name '*.ebuild' -print | sed -e "s/.ebuild//" | cut -d "/" -f 7`
	if [ "`cat /tmp/einfo.ututo-get | wc -l`" -gt 2 ];then
	    echo "-------------------------------------------------"
	    echo "$LANG_SELECT_PACKAGESEARCH"
	    echo " "
	    cat /tmp/einfo.ututo-get
	    echo "-------------------------------------------------"
	    echo "$LANG_DONE"
	    rm -rf /tmp/einfo.ututo-get
	    exit 0
	else
	    ls -1v $REPOSDIR/scripts | grep "$2" | grep -v grep | tail -n 1 > /tmp/einfo.ututo-get
	fi 
	while read PQ
	do
	    echo " "
	    echo "---- $LANG_PACKAGE: "`echo $PQ | sed "s/.sh//"`" ----"
	    cat $REPOSDIR/scripts/$PQ | grep "DESCRIPTION" | sed "s/\"//" | sed "s/\"//" | sed "s/\"//" | sed "s/\"//" | sed "s/\"//" | sed "s/declare //" | head -n 1
	    cat $REPOSDIR/scripts/$PQ | grep "LICENSE" | sed "s/\"//" | sed "s/\"//" | sed "s/\"//" | sed "s/\"//" | sed "s/\"//" | sed "s/\"//" | head -n 1
	    #need=`cat $REPOSDIR/scripts/$PQ | grep ">> /listado-paquetes" | cut -d " " -f 3 | sed "s/.\*//"`
	    #need=`cat $REPOSDIR/scripts/$PQ | grep "\$INSTALAR \$OPCION" | cut -d "\$" -f 3 | cut -d " " -f 2 | sed "s/.tbz2//g" | grep -v "fin"`
	    need=`cat $REPOSDIR/scripts/$PQ | grep "OPCION" | grep ".tbz2" | cut -d "\$" -f 3 | grep -v "fin.tbz2" | cut -d " " -f 2 | sed "s/.tbz2//g"`
	    needcount=`echo $need | wc -w`
	    echo -n "Status: "
	    #PQ2=`cat $REPOSDIR/scripts/$PQ | grep "/usr/bin/emerge unmerge" | cut -d "\"" -f 2 | sed "s/=//"`
	    #EXISTE=`echo "$dbpkg" | grep "$PQ2"`
	    PQ2=`echo $PQ | sed "s/.sh//"`
	    EXISTE=`find /var/db/pkg -type f -name '*.ebuild' -print | sed -e "s/.ebuild//" | grep "$PQ2" | cut -d "/" -f 7`
	    #echo "PQ2: $PQ2"
	    if [ "$EXISTE" = "" ];then
	    	echo "$LANG_NOTINSTALLED"
	    else
	    	echo "$LANG_INSTALLED"
	    fi
	    echo "-------------------------------------------------"
	    echo "$LANG_INFODEPENDENCIES"
	    echo "$LANG_VERIFYINGDEPS ($needcount) ..."
	    #echo "need $need PQ $PQ $REPOSDIR"
	    for P in `echo "$need" | tr " " "\n"`
	    do
		P2=`echo $P | sed "s/http.*\///" | sed "s/.tbz2//"`
		#EXISTE=`echo "$dbpkg" | grep "$P2"`
		P3=`echo $P2 | sed "s/-[0-9].*//"`
		EXISTE=`find /var/db/pkg -type f -name '*.ebuild' -print | sed -e "s/.ebuild//" | grep "$P3" | cut -d "/" -f 7`
		NOINST=`echo "$NOINSTALAR" | grep -E "$P3"`
		#echo "P3: $P3 -- EXISTE: $EXISTE"
		#echo -n "."
		if [ "$NOINST" = "" ];then
		    if [ "$EXISTE" = "" ];then
			echo "$P2 $LANG_NOTINSTALLED"
			#sleep 0
		    else
			#echo "$P2 already installed"
			echo -n "I"
			sleep 0
		    fi
		else
		    printf "$LANG_PACKAGEOMITED" $P2
		fi
	    done
	    echo " "
	    echo "-------------------------------------------------"
	    echo "$LANG_DONE"
	done < /tmp/einfo.ututo-get
	rm -rf /tmp/einfo.ututo-get
	exit 0
fi

###############################################################################
# verfica los parametros
if [ "x$1" = "xupdate" ] && [ $# != 1 ]; then
	uso
	exit 1
else
	if [ "x$1" = "xinstall" -o "x$1" = "xreinstall" -o "x$1" = "xfixdepend"  -o "x$1" = "xremove" -o "x$1" = "xdownload" -o "x$1" = "xfastinstall" -o "x$1" = "xfastreinstall" ] && [ $# != 2 ]; then
		uso
		exit 1
	fi
fi
if [ ! -d $PKGDIR ]; then
	NDIR=""
	for DIR in ${PKGDIR//\// }
	do
		NDIR="$NDIR/$DIR"
		if [ ! -d $NDIR ]; then
			mkdir $NDIR 2> /dev/null
		fi
	done
fi

###############################################################################
# Aqu�baja disponibles.tar.bz2, actualiza la lista de scripts
# y actualiza todos los dem� scripts y claves de admin de UTUTO
if [ "x$1" = "xupdate" ]; then
	updateUtutoGet
	exit
fi

###############################################################################
# Actualiza el arbol del portage de UTUTO para poder compilar con emerge
if [ "x$1" = "xportage" ]; then
	updatePortage
	exit
fi

###############################################################################
# Simplemente llama a emerge --unmerge si la accion seleccionada es remove
if [ "x$1" = "xremove" ]; then
	EXISTE=`find /var/db/pkgbin/sys-debinstall -type f -name '*.ebuild' -print | sed -e "s/.ebuild//" | grep "$2" | cut -d "/" -f 7`
	if [ "`echo $EXISTE | wc -w`" -gt 1 ];then
	    echo "-----------------------------------------------------"
	    echo "Please select package / Seleccione paquete:"
	    echo "$EXISTE"
	    echo "-----------------------------------------------------"
	    exit 0
	fi
	if [ "$EXISTE" != "" ];then
	    let CONT=0
	    echo "Removing DEB package $EXISTE"
	    echo -n "Removing / Eliminando $EXISTE (CTRL+C to cancel)... "
	    beepNSecs 9
	    while [ $CONT -lt 50 ]
	    do
		for fileremove in `cat /var/db/pkgbin/sys-debinstall/$EXISTE/CONTENTS`
		do
		    sleep 0
		    rm -d /$fileremove 2>/dev/null
		done
		let CONT+=1
	    done
	    rm -rf /var/db/pkgbin/sys-debinstall/$EXISTE 2>/dev/null
	    rm -d /var/db/pkgbin/sys-debinstall 2>/dev/null
	    rm -d /var/db/pkgbin 2>/dev/null
	    exit 0
	fi
	EXISTE=`find /var/db/pkgbin/sys-rpminstall -type f -name '*.ebuild' -print | sed -e "s/.ebuild//" | grep "$2" | cut -d "/" -f 7`
	if [ "`echo $EXISTE | wc -w`" -gt 1 ];then
	    echo "-----------------------------------------------------"
	    echo "Please select package / Seleccione paquete:"
	    echo "$EXISTE"
	    echo "-----------------------------------------------------"
	    exit 0
	fi
	if [ "$EXISTE" != "" ];then
	    let CONT=0
	    echo "Removing RPM package $EXISTE"
	    echo -n "Removing / Eliminando $EXISTE (CTRL+C to cancel)... "
	    beepNSecs 9
	    while [ $CONT -lt 50 ]
	    do
		for fileremove in `cat /var/db/pkgbin/sys-rpminstall/$EXISTE/CONTENTS`
		do
		    rm -d /$fileremove 2>/dev/null
		done
		let CONT+=1
	    done
	    rm -rf /var/db/pkgbin/sys-rpminstall/$EXISTE 2>/dev/null
	    rm -d /var/db/pkgbin/sys-rpminstall 2>/dev/null
	    rm -d /var/db/pkgbin 2>/dev/null
	    exit 0
	fi
	EXISTE=`find /var/db/pkgbin/sys-txzinstall -type f -name '*.ebuild' -print | sed -e "s/.ebuild//" | grep "$2" | cut -d "/" -f 7`
	if [ "`echo $EXISTE | wc -w`" -gt 1 ];then
	    echo "-----------------------------------------------------"
	    echo "Please select package / Seleccione paquete:"
	    echo "$EXISTE"
	    echo "-----------------------------------------------------"
	    exit 0
	fi
	if [ "$EXISTE" != "" ];then
	    let CONT=0
	    echo "Removing TXZ package $EXISTE"
	    echo -n "Removing / Eliminando $EXISTE (CTRL+C to cancel)... "
	    beepNSecs 9
	    while [ $CONT -lt 50 ]
	    do
		for fileremove in `cat /var/db/pkgbin/sys-txzinstall/$EXISTE/CONTENTS`
		do
		    rm -d /$fileremove 2>/dev/null
		done
		let CONT+=1
	    done
	    rm -rf /var/db/pkgbin/sys-txzinstall/$EXISTE 2>/dev/null
	    rm -d /var/db/pkgbin/sys-txzinstall 2>/dev/null
	    rm -d /var/db/pkgbin 2>/dev/null
	    exit 0
	fi
	echo "Removing UTUTO XS package $2..."
	echo -n "Removing / Eliminando $2 (CTRL+C to cancel)... "
	beepNSecs 9
	emerge --unmerge -v -q "$2" 2>/dev/null
	#verificarLibrerias
	registrarAcciones $1 $2
	echo
	printf "$LANG_PACKAGEREMOVED" $2
	echo -e "$WHITE $LANG_DONE!$NO_COLOUR"
	echo
	exit
fi

###############################################################################
# Actualiza los principales paquetes del sistema

#if [ "x$1" = "xdist-upgrade" ]; then
if [ "`echo $1 | grep dist-upgrade`" != "" ]; then
	#distUpgrade
	[[ ! -d $ugettmpdir ]] && mkdir -p $ugettmpdir
	cd $ugettmpdir
	FILE="$1"
	if [ "x$2" = "x" ]; then
	    SYSTEMNAME=`head /system.name -n 1`
	    SYSTEMID="$SYSTEMNAME"
	else
	    SYSTEMID=".$2"
	fi
	FILE="$1$SYSTEMID"
	$GETPKG --quiet $UTUTOGET_URL/$FILE.sh
	if [ -e $ugettmpdir/$FILE.sh ];then
	    echo "Uograding system version with... $FILE"
	    eInfo "${LANG_UPDATEINPROGRESS}"
	    eInfo "${LANG_INSTALLINGINSECONDS}\n"
	    chmod 755 $ugettmpdir/$FILE.sh
	    chown root.root $ugettmpdir/$FILE.sh
	    beepNSecs 9
	    nice -n -19 bash -x -c "$ugettmpdir/$FILE.sh &"
	    sleep 0
	else
	    echo "File $FILE dont exist!!. Exiting.." 
	    sleep 0
	fi   
	exit
fi

if [ "`echo $1 | grep xs-update`" != "" ]; then
	#xsUpdate
	[[ ! -d $ugettmpdir ]] && mkdir -p $ugettmpdir
	cd $ugettmpdir
	FILE="$1"
	if [ "x$2" = "x" ]; then
	    SYSTEMNAME=`head /system.name -n 1`
	    SYSTEMID="$SYSTEMNAME"
	else
	    SYSTEMID=".$2"
	fi
	FILE="$1$SYSTEMID"
	$GETPKG --quiet $UTUTOGET_URL/$FILE.sh
	if [ -e $ugettmpdir/$FILE.sh ];then
	    echo "Upgrading system with... $FILE"
	    eInfo "${LANG_UPDATEINPROGRESS}"
	    eInfo "${LANG_INSTALLINGINSECONDS}\n"
	    chmod 755 $ugettmpdir/$FILE.sh
	    chown root.root $ugettmpdir/$FILE.sh
	    beepNSecs 9
	    nice -n -19 bash -x -c "$ugettmpdir/$FILE.sh &"
	    sleep 0
	else
	    echo "File $FILE dont exist!!. Exiting..."
	    echo "System not updated." 
	    sleep 0
	fi   
	exit
fi

#if [ "x$1" = "xpatch-upgrade" ]; then
if [ "`echo $1 | grep patch-upgrade`" != "" ]; then
	#patchUpgrade
	[[ ! -d $ugettmpdir ]] && mkdir -p $ugettmpdir
	cd $ugettmpdir
	FILE="$1"
	if [ "x$2" = "x" ]; then
	    SYSTEMNAME=`head /system.name -n 1`
	    SYSTEMID="$SYSTEMNAME"
	else
	    SYSTEMID=".$2"
	fi
	FILE="$1$SYSTEMID"
	$GETPKG --quiet $UTUTOGET_URL/$FILE.sh
	if [ -e $ugettmpdir/$FILE.sh ];then
	    echo "Applying system patch $FILE..."
	    eInfo "${LANG_UPDATEINPROGRESS}"
	    eInfo "${LANG_INSTALLINGINSECONDS}\n"
	    chmod 755 $ugettmpdir/$FILE.sh
	    chown root.root $ugettmpdir/$FILE.sh
	    beepNSecs 9
	    nice -n -19 bash -x -c "$ugettmpdir/$FILE.sh &"
	    sleep 0
	else
	    echo "Patch file $FILE dont exist!!. Exiting.." 
	    sleep 0
	fi   
	exit
fi

if [ $# -eq 1 ]; then
	PATRONBUSQUEDA=$1-
	ACTION=install
else
	PATRONBUSQUEDA=$2
fi

###############################################################################
# A continuaci� instala el software solicitado, solo para las siguientes acciones 
if [ $# -ne 1 -a "x$1" != "xinstall" -a "x$1" != "xreinstall" -a "x$1" != "xfixdepend" -a "x$1" != "xdownload" -a "x$1" != "xfastinstall" -a "x$1" != "xfastreinstall" ]; then
	echo "$LANG_INCORRECTPARAMETERS";echo
	uso
	exit 1
fi

###############################################################################
# Detecta el procesador
leerProcesador
echo "PROCESSOR: $PROCESSOR"


###############################################################################
# Selecciona el paquete a instalar
PACK=$(seleccionarPaquete $PATRONBUSQUEDA)

if [ "$PACK" = "" ]; then
	echo "$LANG_PACKAGENOTFOUND"
	echo "-------------------------------------------------------------------------------------"
	echo "Command executed: uget $1 $2"
	DA_NOTFOUND=`ps ax | grep dist-upgrade | grep -v grep`
	if [ DA_NOTFOUND != "" ];then
	    FECHA=`date`
	    echo "PACKAGE NOT FOUND - $FECHA - Command executed: uget $1 $2" >> /dist-upgrade.notfound
	    echo "---------------------------------------------------------------------------------------" >> /dist-upgrade.notfound
	fi 
	echo "-------------------------------------------------------------------------------------"
	echo "$LANG_PACKAGEEMERGE"
	if [ "$2" = "" ];then
	    emerge --search -v -q $1 2>/dev/null
	else
	    emerge --search -v -q $2 2>/dev/null
	fi
	echo "-------------------------------------------------------------------------------------"
	echo "Press [ENTER] to continue..."
	echo " "
	read -t 10000
	exit
fi

echo; echo -e "$LANG_INSTALLING: [$WHITE $PACK $NO_COLOUR]"

###############################################################################
# EL SIGUIENTE CODIGO CADUCO A PARTIR DEL KERNEL 2.6.23
###############################################################################
# Los kernel no pueden ser instalados por ututo-get, ya que el script de instalación es muy diferente al resto y bastante complejo
# ESKERNEL=`expr "$PACK" : 'linux-2'`
# if [ $ESKERNEL -gt 0  ]; then
# 	echo; echo -e "$LANG_INSTALLINGKERNEL"
# 	printf "$LANG_INSTALLINGORIGINALSCRIPT" $PACK
# 	echo -e "$LANG_INSTALLINGINSECONDS"
# 	for i in 1 2 3 4 5 6 7 8 9 10; do
# 		echo -en "$BEEP$i "; sleep 1s;
# 	done
# 	echo "Go!"; echo
# 	cp $REPOSDIR/scripts/$PACK.sh /
# 	cd /
# 	sh /$PACK.sh
# 
# 	echo
# 	printf "$LANG_PACKHASBEENINSTALLED" $PACK
# 	echo -e "$WHITE $LANG_DONE!$NO_COLOUR"
# 	echo
# 
# 	exit
# fi
###############################################################################

###############################################################################
# Obtiene la lista de dependencias desde el script de instalaci� generado por el kit de desarrollo
obtenerDependencias

echo; echo "$LANG_VERIFYINGDEPS"; echo
#sleep 2s

###############################################################################
# Al instalar xorg-server elimina los ebuilds de los modulos para que sean actualizados
# set -x
VERS_TE="1.12"
VERS_ST="1.12"
XORGVERSION_TESTING="1.12.1"
XORGVERSION_ESTABLE="1.12.1"
if [[ $(echo "$PAQUETES" | grep "xorg-server-" | wc -l) -gt 0  ]]; then
    if [ "$REPOSITORIO" = "disponibles_testing" ];then	
      if [[ $(echo "$PAQUETES" | grep "xorg-server-$XORGVERSION_TESTING" | wc -l) -gt 0  ]]; then
	#if [ $(find /var/db/pkg/ -name "xorg-server-*.ebuild" | sed "s/.*\///g" | sed "s/\.ebuild$//g" | wc -l) -eq 0 ];then
	NUEVA=`echo "$PAQUETES" | grep "xorg-server-$XORGVERSION_TESTING" | grep -v "grep " | cut -d "/" -f 5 | sed "s/.tbz2//g"`
	EXISTENTE=`find /var/db/pkg/ -name "xorg-server-*.ebuild" | sed "s/.*\///g" | sed "s/\.ebuild$//g"`
	NEWMODULES=`find /var/db/pkg/ -name "xorg-server-*.ebuild" | sed "s/.*\///g" | sed "s/\.ebuild$//g" | grep $VERS_TE`
	if [ "$NUEVA" != "$EXISTENTE" ];then
		echo "XORG-SERVER OLD: $EXISTENTE"
		echo "XORG-SERVER NEW: $NUEVA"
	    if [ "$NEWMODULES" != "" ];then
		echo "Modules don't need actualization only new version of xorg-server must be installed"
	    else
		sleep 0
		ACTUALDIR=`pwd`
		cd /var/db/pkg/x11-drivers/
		echo "Removing old testing X drivers for X server: $EXISTENTE..."
		waitNSecs 10
		emerge --unmerge -v -q * 2>/dev/null
		emerge --unmerge -v -q xorg-server 2>/dev/null
		#emerge --unmerge xorg-x11
		emerge --unmerge -v -q mesa 2>/dev/null
		rm -rf /usr/portage/packages/All/xf86-*
		rm -rf /usr/portage/packages/All/xorg-*
		rm -rf /usr/portage/packages/All/mesa-*
		#rm -rf /var/db/pkg/x11-drivers/*
		cd $ACTUALDIR
	    fi
	fi
      fi
    else
      if [[ $(echo "$PAQUETES" | grep "xorg-server-$XORGVERSION_ESTABLE" | wc -l) -gt 0  ]]; then
	#if [ $(find /var/db/pkg/ -name "xorg-server-*.ebuild" | sed "s/.*\///g" | sed "s/\.ebuild$//g" | wc -l) -eq 0 ];then
	NUEVA=`echo "$PAQUETES" | grep "xorg-server-$XORGVERSION_ESTABLE" | grep -v "grep " | cut -d "/" -f 5 | sed "s/.tbz2//g"`
	EXISTENTE=`find /var/db/pkg/ -name "xorg-server-*.ebuild" | sed "s/.*\///g" | sed "s/\.ebuild$//g"`
	NEWMODULES=`find /var/db/pkg/ -name "xorg-server-*.ebuild" | sed "s/.*\///g" | sed "s/\.ebuild$//g" | grep $VERS_ST`
	if [ "$NUEVA" != "$EXISTENTE" ];then
		echo "XORG-SERVER OLD: $EXISTENTE"
		echo "XORG-SERVER NEW: $NUEVA"
	    if [ "$NEWMODULES" != "" ];then
		echo "Modules don't need actualization only new version of xorg-server must be installed"
	    else
		sleep 0
		ACTUALDIR=`pwd`
		cd /var/db/pkg/x11-drivers/
		echo "Removing old stable X drivers for X server: $EXISTENTE..."
		waitNSecs 10
		emerge --unmerge -v -q * 2>/dev/null
		emerge --unmerge -v -q xorg-server 2>/dev/null
		#emerge --unmerge xorg-x11
		emerge --unmerge -v -q mesa 2>/dev/null
		rm -rf /usr/portage/packages/All/xf86-*
		rm -rf /usr/portage/packages/All/xorg-*
		rm -rf /usr/portage/packages/All/mesa-*
		#rm -rf /var/db/pkg/x11-drivers/*
		cd $ACTUALDIR
	    fi
	fi
      fi
    fi
fi
# set +x 

###############################################################################
# Solo instala los paquetes que no se encuentran previamente instalados en el sistema
# La siguiente l�ea cachea en memoria todos los paquetes instalados en el sistema para buscar mas r�ido
# dbpkg=`ls -1R /var/db/pkg | grep ".ebuild" | sed "s/.ebuild//"`
# Esta parece ser mas rapida que la linea anterior
dbpkg=`find /var/db/pkg/ -name *.ebuild | sed "s/.*\///g" | sed "s/\.ebuild$//g"`
# TODO: Hay que hacer algo para que detecte las revisiones, ya que el nombre del script y el nombre del tbz2 son diferentes. Ej: gftp-2.0.18-r4
# Un intento fue este, que detecta los "-rNN" pero deja fuera los "-alphaNN" y dem�
# PACK=`echo $PACK | sed "s/\(-[0-9]*[.][0-9]*[.][0-9]*\)\([.]\)\([0-9]*\)$/\1-r\3/"`
EXISTE=`echo "$dbpkg" | grep "$PACK"`
if [ "x$EXISTE" != "x" -a "x$ACTION" != "xreinstall" -a "x$ACTION" != "xfixdepend" -a "x$ACTION" != "xdownload" -a "x$ACTION" != "xfastreinstall" ]; then
	echo -e "$BEEP"
	echo -e "$LANG_PACKAGEALREADYINSTALLED"
	exit;
fi


[[ ! -f $CONFIGDIR/ututo-get.omit ]] && touch $CONFIGDIR/ututo-get.omit
sed -i "/^$/d" $CONFIGDIR/ututo-get.omit

for P in `echo "$PAQUETES" | tr " " "\n"`
do

	rm -rf $ugettmpdir/*

	P2=`echo $P | sed "s/http.*\///" | sed "s/.tbz2//"`
	EXISTE=`echo "$dbpkg" | grep "$P2"`

	NOINST=$(echo "$P2" | grep -f $CONFIGDIR/ututo-get.omit)

	if [[ $ACTION = reinstall ]]; then
		AINSTALAR="$AINSTALAR $P"
	elif [ "$NOINST" = "" ];then
	    if [ "$EXISTE" = "" -o "x$ACTION" = "xfastreinstall" ];then
	    	paquetelimpio=$(echo $P2 |  sed -r "s/-[0-9.]+([a-z])?(((_alpha|_rc|_pre|_p|_r|_beta)([0-9])*)?(-|_)[a-z]+[0-9]+)?//")
	    	paqueteinstalado=$(echo "$dbpkg" | tr " " "\n" | grep -E "^${paquetelimpio/+/\\+}-[0-9.]+([a-z])?(((-alpha|-rc|-pre|-p|-r|-beta)([0-9])*)?(-|_)[a-z]+[0-9]+)?" )
			
			P3=$(echo $P2 | sed -r -e "s/(-[0-9.]+)-alpha/\1_000_/" -e "s/(-[0-9.]+)-beta/\1_001_/" -e "s/(-[0-9.]+)-pre/\1_002_/" -e "s/(-[0-9.]+)-rc/\1_003_/" -e "s/(-[0-9.]+)-r([0-9]+)/\1_004_\2/" -e "s/(-[0-9.]+)-p([0-9]+)/\1_005_\2/")
# 			echo $P3
			touch $ugettmpdir/$P3.0
			for pinst in $paqueteinstalado; do
				pinst2=$(echo $pinst | sed -r -e "s/(-[0-9.]+)-alpha/\1_000_/" -e "s/(-[0-9.]+)-beta/\1_001_/" -e "s/(-[0-9.]+)-pre/\1_002_/" -e "s/(-[0-9.]+)-rc/\1_003_/" -e "s/(-[0-9.]+)-r([0-9]+)/\1_004_\2/" -e "s/(-[0-9.]+)-p([0-9]+)/\1_005_\2/")
# 				echo $pinst2
				touch $ugettmpdir/$pinst2.0
			done
			cd $ugettmpdir
			paquetenuevo=$(ls -1v $paquetelimpio*0 2>/dev/null | sed -r -e "s/(-[0-9.]+)\.0(_alpha|_rc|_pre|_p|_r|_beta)/\1/" \
									-e "s/(-[0-9.]+)_000_/\1_alpha/" \
									-e "s/(-[0-9.]+)_001_/\1_beta/" \
									-e "s/(-[0-9.]+)_002_/\1_pre/" \
									-e "s/(-[0-9.]+)_003_/\1_rc/" \
									-e "s/(-[0-9.]+)_005_([0-9]+)/\1_p\2/" \
									-e "s/(-[0-9.]+)_004_([0-9]+)/\1-r\2/" | tail -n 1)
# 			ls -1v $paquetelimpio*0
			[[ $ACTION = reinstall || $ACTION = fastreinstall ]] && reinstalar=1 || reinstalar=0
			if [[ $paquetenuevo = $P2.0 || $reinstalar = 1 ]]; then
				AINSTALAR="$AINSTALAR $P"
				echo -n .
			else 
				echo -n I
			fi
			set +x
	    else
			echo -n I
	    fi
	else
	    printf " $LANG_PACKAGEOMITED " $P2
	fi

done

echo; echo -e "$LANG_PACKAGESTOBEINSTALLED"; echo
#sleep 2s

###############################################################################
# La variable AINSTALAR contiene las dependencias que faltan en el sistema y el paquete mismo solicitado
echo $AINSTALAR | tr " " "\n" | sed "s/http.*\///" | sed "s/.tbz2//"
echo -e "$BEEP"

if [ "x$ACTION" = "xfixdepend" -a "x$AINSTALAR" = "x" ]; then
	printf "$LANG_PACKHASBEENED" $PACK $ACTION
	echo -e "$WHITE $LANG_DONE!$NO_COLOUR"
	echo
	exit
fi

read -t $TOUT -p "$LANG_CONFIRMCONTINUE" CONFIRMA
if [ "$CONFIRMA" = "n" -o "$CONFIRMA" = "N" ]; then
	echo "$LANG_CANCELEDBYUSER"
	exit
fi
echo

###############################################################################
# Descarga los binarios a instalar
mkdir -p $PKGDIR &> /dev/null
cd $PKGDIR

AINSTALAR=`echo $AINSTALAR | sed "s/https:/$PROTOCOL_PKG:/g"`;
NROPAQUETES=`echo $AINSTALAR |  wc -w`
let AVANCE=0
for P in $AINSTALAR
do
	# Si existen los tres archivos asume que se descargaron completamente,
	# la mayor� de las veces esto es cierto, si alguno no est�descargado por
	# comleto fallar�la verficaci� de firmas y ser�descargado nuevamente en
	# la pr�ima ejecuci� del script
	P2="`echo $P | sed "s/http.*\///"`"
	let AVANCE+=1
	####if [ ! -f "$PKGDIR/$P2"  -o  ! -f "$PKGDIR/$P2.sig1"  -o  ! -f "$PKGDIR/$P2.sig2" ]; then
	if [ ! -e $PKGDIR/$P2 ];then
		if [ "$REPOSITORIO" = "disponibles_testing" ];then
		    PT="`echo $P | sed "s/$P2/utiles\/00Testing\/$P2/"`"
		    OPTIDOWN="`echo $P | cut -d "/" -f 4`"
		    PT="`echo $P | sed "s/$OPTIDOWN\///"`"
		    PT="`echo $PT | sed "s/$P2/utiles\/00Testing\/$OPTIDOWN\/$P2/"`"
		    echo -e "----\n$WHITE$AVANCE / $NROPAQUETES$NO_COLOUR Downloading (Testing New Package) $WHITE $PT $NO_COLOUR for $PROCESSOR..."
		    #echo "$GETPKG (Testing New Package) $PT"
		    $GETPKG $PT
		    if [ ! -e $PKGDIR/$P2.sig1 ];then
			#echo "$GETPKG --quiet $PT.sig1"
			$GETPKG --quiet $PT.sig1 &
		    fi
		    if [ ! -e $PKGDIR/$P2.sig2 ];then
			#echo "$GETPKG --quiet $PT.sig2"
			$GETPKG --quiet $PT.sig2 &
		    fi
		    #
		    # Si no esta busca en Stable
		else
		    echo -e "----\n$WHITE$AVANCE / $NROPAQUETES$NO_COLOUR Downloading (Stable) $WHITE $P2 $NO_COLOUR for $PROCESSOR..."
		    #echo "$GETPKG $P"
		    $GETPKG $P
		    if [ ! -e $PKGDIR/$P2.sig1 ];then
			#echo "$GETPKG --quiet $P.sig1"
			$GETPKG --quiet $P.sig1 &
		    fi
		    if [ ! -e $PKGDIR/$P2.sig2 ];then
			#echo "$GETPKG --quiet $P.sig2"
			$GETPKG --quiet $P.sig2 &
		    fi
		fi
	fi
	if [ ! -e $PKGDIR/$P2 ];then
		    echo -e "----\n$WHITE$AVANCE / $NROPAQUETES$NO_COLOUR Downloading (Stable) $WHITE $P2 $NO_COLOUR for $PROCESSOR..."
		    echo "$GETPKG $P"
		    $GETPKG $P
		    if [ ! -e $PKGDIR/$P2.sig1 ];then
			#echo "$GETPKG --quiet $P.sig1"
			$GETPKG --quiet $P.sig1 &
		    fi
		    if [ ! -e $PKGDIR/$P2.sig2 ];then
			#echo "$GETPKG --quiet $P.sig2"
			$GETPKG --quiet $P.sig2 &
		    fi
	fi
	if [ ! -e $PKGDIR/$P2 ];then
		    echo -e "----\n$WHITE$AVANCE / $NROPAQUETES$NO_COLOUR Downloading (Stable) $WHITE $P2 $NO_COLOUR for $PROCESSOR..."
		    echo "$GETPKG $P"
		    $GETPKG $P
		    if [ ! -e $PKGDIR/$P2.sig1 ];then
			#echo "$GETPKG --quiet $P.sig1"
			$GETPKG --quiet $P.sig1 &
		    fi
		    if [ ! -e $PKGDIR/$P2.sig2 ];then
			#echo "$GETPKG --quiet $P.sig2"
			$GETPKG --quiet $P.sig2 &
		    fi
	fi
	if [ ! -e $PKGDIR/$P2 ];then
		    echo -e "----\n$WHITE$AVANCE / $NROPAQUETES$NO_COLOUR Downloading (Stable) $WHITE $P2 $NO_COLOUR for $PROCESSOR..."
		    echo "$GETPKG $P"
		    $GETPKG $P
		    if [ ! -e $PKGDIR/$P2.sig1 ];then
			#echo "$GETPKG --quiet $P.sig1"
			$GETPKG --quiet $P.sig1 &
		    fi
		    if [ ! -e $PKGDIR/$P2.sig2 ];then
			#echo "$GETPKG --quiet $P.sig2"
			$GETPKG --quiet $P.sig2 &
		    fi
	fi
done
wait

# Esto es necesario para evitar algn problema que and�a saber cual es
#AINSTALAR="$AINSTALAR libstdc++-v3-3.3.6.tbz2"
#EXISTETBZ2=`ls -1 $PKGDIR/libstdc++-v3-3.3.6.tb#z2 | wc -l`
#EXISTESIG1=`ls -1 $PKGDIR/libstdc++-v3-3.3.6.tbz2.sig1 | wc -l`
#EXISTESIG2=`ls -1 $PKGDIR/libstdc++-v3-3.3.6.tbz2.sig2 | wc -l`
#if [ "$EXISTETBZ2" = "0"  -o  "$EXISTESIG1" = "0"  -o  "$EXISTESIG2" = "0" ];then
#	if [ "$PROCESSOR" = "i486" ];then
#		$GET $PROTOCOL_PKG://$SERVER_PKG/i486/libstdc++-v3-3.3.6.tbz2
#		$GET $PROTOCOL_PKG://$SERVER_PKG/i486/libstdc++-v3-3.3.6.tbz2.sig1
#		$GET $PROTOCOL_PKG://$SERVER_PKG/i486/libstdc++-v3-3.3.6.tbz2.sig2
#	else
#		$GET $PROTOCOL_PKG://$SERVER_PKG/i686/libstdc++-v3-3.3.6.tbz2
#		$GET $PROTOCOL_PKG://$SERVER_PKG/i686/libstdc++-v3-3.3.6.tbz2.sig1
#		$GET $PROTOCOL_PKG://$SERVER_PKG/i686/libstdc++-v3-3.3.6.tbz2.sig2
#	fi
#fi

###############################################################################
# Verifica que los archivos se hayan descargado correctamente
verificaFirmas $AINSTALAR

if [ "x$1" = "xdownload" ]; then

	echo -e "$BEEP"
	echo -e "$LANG_ALLBINARIESDOWNLOADED"
	exit 0;
fi

#echo -e "$BEEP"
#echo -e "$LANG_INSTALLINGINSECONDS"
#for i in 1 2 3 4 5; do
#	echo -en "$BEEP $i " ; sleep 1s ; killall ldd 2>/dev/null ; killall check-ldd 2>/dev/null
#done
#echo "$LANG_GO"; echo

###############################################################################
# Instala el software solicitado y todas sus dependencias faltantes
instalarPaquetes $PATRONBUSQUEDA

if [ "x$ACTION" != "xverify" ]; then
	#echo -e "$LANG_CHECKLDDINBACKGROUND"
	verificarLibrerias &>/dev/null &
else
	verificarLibrerias
fi

auto-update-etc.sh 2>/dev/null

registrarAcciones $ACTION $PACK

rm -rf $ugettmpdir

echo
printf "$LANG_PACKHASBEENED" $PACK $ACTION
echo -e "$WHITE $LANG_DONE!$NO_COLOUR"
echo
###############################################################################
