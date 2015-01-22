#!/bin/bash
# ututo-get.es.sh - shell script
#
# Autor: Pablo Manuel Rizzo <info@pablorizzo.com>
#
# Copyright (C) 2004 - 2007 The UTUTO Project
# Distributed under the terms of the GNU General Public License v3 or new
#
# $Header: $

LANG_IMPORTANT_NOTICE_GLIBC="--------------------------------------------------------------------------------
ATENCION! IMPORTANTE: Leer atentamente


Usted ""$WHITE""debe actualizar el paquete GLIBC antes de instalar cualquier otro software, de esta manera: 

$WHITE ututo-get install glibc $NO_COLOUR

NOTA PARA USUARIOS COMUNES DE ESCRITORIO (NO SERVIDORES): si utiliza interfaz gráfica mediante Xorg,
luego de actualizar GLIBC ""$WHITE""debe""$NO_COLOUR"" actualizar Xorg: 

$WHITE ututo-get install xorg $NO_COLOUR

--------------------------------------------------------------------------------"

LANG_SINTAX_BASIC="Sintaxis: ""$WHITE""uget <ACCION> [paquete]
	$NO_COLOUR""ACCION:
	""$WHITE""<paquete>
		""$NO_COLOUR""Descarga e instala ultima versión de <paquete>
	""$WHITE""install
		""$NO_COLOUR""Lista, descarga e instala versiones de <paquete>.
	""$WHITE""installpkg
		""$NO_COLOUR""Instala <paquete> binario. Puede ser tbz2 (Basado en Gentoo), txz (Slackware), deb (Basado en Debian) o rpm (Basado en RedHat)
	""$WHITE""update
		""$NO_COLOUR""Actualiza la lista de paquetes y algunos scripts del sistema
	""$WHITE""xs-update
		""$NO_COLOUR""Actualiza todos los paquetes del sistema a nuevas versiones disponibles (Este proceso puede llevar mucho tiempo)
	""$WHITE""reinstall
		""$NO_COLOUR""Descarga y reinstala <paquete> y todas sus dependencias (aunque ya estuvieran instalados)
	""$WHITE""fixdepend
		""$NO_COLOUR""Descarga e instala cualquier dependencia de <paquete> que no estuviera instalada o que exista una versión mas nueva
	""$WHITE""remove
		""$NO_COLOUR""Desinstala <paquete>
	""$WHITE""info
		""$NO_COLOUR""Muestra información sobre <paquete>
	""$WHITE""download
		""$NO_COLOUR""Descarga (pero no instala) <paquete> y todas sus dependencias no instaladas o desactualizadas
	""$WHITE""fastinstall
		""$NO_COLOUR""Descarga e instala <paquete> pero SIN VERIFICAR NI INSTALAR dependencias (CUIDADO! PUEDE DAÑAR SU SISTEMA CON FACILIDAD!)
	""$WHITE""fastreinstall
		""$NO_COLOUR""Descarga y reinstala <paquete> pero SIN VERIFICAR NI INSTALAR dependencias (CUIDADO! PUEDE DAÑAR SU SISTEMA CON FACILIDAD!)
	""$WHITE""verify
		""$NO_COLOUR""Verifica e instala librerías faltantes en el sistema
	""$WHITE""autoupgradeuget
		""$NO_COLOUR""Si hay una nueva versión de ututo-get, descargarla e instalarla
	""$WHITE""dist-upgrade
		""$NO_COLOUR""Actualizar $SYSTEMNAME2 a una nueva version disponible (Este proceso puede llevar mucho tiempo)
	""$WHITE""skel
		""$NO_COLOUR""Actualizar el skel de sistema en $SYSTEMNAME2
	""$WHITE""skelinstall
		""$NO_COLOUR""Actualizar el skel de sistema en $SYSTEMNAME2 actualizando configuraciones y aplicandolo a los usuarios
	""$WHITE""search
		""$NO_COLOUR""Listar los paquetes segun criterio de busqueda en $SYSTEMNAME2
	""$WHITE""category
		""$NO_COLOUR""Listar los paquetes de una categoria en $SYSTEMNAME2
	""$WHITE""changelog
		""$NO_COLOUR""Ver los ultimos cambios incorporados en $SYSTEMNAME2
	""$WHITE""cpu
		""$NO_COLOUR""Ver detalles del hardware y el sistema
	""$WHITE""develkit
		""$NO_COLOUR""Instalar el Kit de Desarrollo para $SYSTEMNAME2
"

LANG_DOWNLOADING="descargando"
LANG_DONE="hecho"
LANG_FAILED="falló"
LANG_DOWNSKEL="Descargando e instalando nuevo skel"
LANG_BINERROR="Paquete binario no reconocido"
LANG_FIXING="Corrigiendo archivos de configuracion y usuarios"
LANG_NOTFOUND="no encontrado."
LANG_PROFILE="Perfil"
LANG_SKELPREVINST="Skel ya instalado"
LANG_IMPORTKEYS="Importando claves"
LANG_REMOVING="Eliminando paquete"

LANG_CHECK_VERSION_UTUTOGETSH="Verificando versión de ututo-get [%s]..."
LANG_CHECK_VERSION_UTUTOGETCONF="Verificando versión de ututo-get.conf..."
LANG_CHECK_VERSION_UTUTOGETKMDR="Verificando versión de ututo-get.kmdr..."
LANG_CHECK_VERSION_UTUTOGETDESKTOP="Verificando versión de ututo-get.desktop..."
LANG_CHECK_VERSION_UTUTOGETMSG="Verificando versión de %s..."
LANG_UTUTOGETSH_NEWVERSION="Hay una nueva versión de ututo-get disponible"
LANG_UTUTOGET_WILLUPGRADE="ututo-get will auto-upgrade now..."
LANG_CHECK_VERSION_REPOSITORY="Verificando nuevos paquetes en el repositorio [$REPOSITORIO]..."
LANG_UPDATING_CHECKLDD="Actualizando check-ldd..."
LANG_UPDATING_CHECKLDD_FAILED="\nNo se pudo descargar la herramienta check-ldd, no se puede continuar. 
Por favor, verifique si tiene acces a la siguiente URL:
		\n\n $CHECKLDD_URL"

LANG_SELECT_PROCESSOR="Por favor, seleccione el tipo de procesador que utiliza (si no está seguro elija \"i686\"):"
LANG_SELECTED_PROCESSOR="Processor %s selected"
LANG_NO_PROCESSOR="No se ha podido seleccionar el tipo de procesador que utiliza. No se puede continuar. $BEEP"

LANG_SELECT_LAST_PACKAGE="\nExisten varias versiones disponibles de este paquete, probablemente usted está buscando esta: ""$WHITE""%s""$NO_COLOUR"" $BEEP
Desea instalar esta versión? (ingrese 'no' para ver otras versiones disponibles)\n"
LANG_INSTALL_DEFAULT="Instalar ""$WHITE""%s""$NO_COLOUR""? [""$WHITE""Y""$NO_COLOUR""|n]: "

LANG_SELECT_PACKAGE="\nVarias opciones coinciden con su selección.\n""$WHITE""Seleccione un paquete para instalar:""$NO_COLOUR"""
LANG_CANCELEDBYUSER="Operación cancelada por el usuario."

LANG_GPG_OK="Estado: firmas de paquetes OK"
LANG_GPG_ERROR="ERROR AL VERIFICAR LAS FIRMAS DEL PAQUETE!!!!"
LANG_GPG_NOTFOUNDREQUIRED="$WHITE No se pudo encontrar el paquete requerido \"%s.tbz2\". El paquete es necesario por lo que la instalación se abortará.$NO_COLOUR"
LANG_GPG_CONTINUEDOWNLOAD="Continuar descargando los demás paquetes? [Y|n]: "
LANG_GPG_NOTFOUNDCANCELLING="Archivos no encontrado %s.tbz2. Cancelando instalación."
LANG_GPG_RESTARTINSTALLATION="ERROR: algunos archivos no han podido ser verificados. Por favor, reinicie la instalación para intentar descargarlos nuevamente."
LANG_GPG_REPORT="Por favor, reporte el problema $WHITE""http://bugs.ututo.org""$NO_COLOUR. Copie y envíe las siguientes líneas al equipo de desarrollo:"

LANG_OMITINGCUPSPOSTINSTALL="$WHITE #### OMITIENDO tareas de postinstalación para %s #### $NO_COLOUR \n"
LANG_POSTINSTALLTASKS="$WHITE #### Tareas de postinstalación para %s #### $NO_COLOUR \n Esto puede demorar varios minutos, se paciente..."
LANG_INSTALLINGPACKAGE="\nINSTALANDO: ""$WHITE""%s""$NO_COLOUR\n"
LANG_PROCESSINGICONS="Procesando iconos..."
LANG_PROCESSINGINFOFILES="Procesando info-files..."
LANG_REMOVINGOLDPACKAGES="Removiendo paquetes viejos..."
LANG_PROCESSINGLIBRARIES="Procesando librerías..."

LANG_UPDATEINPROGRESS="$WHITE""Actualización en progreso...""$NO_COLOUR\n"
LANG_UPDATING_ECLASS="$WHITE""Actualizando eclass...""$NO_COLOUR"
LANG_UPDATING_ECLASS_ERROR="ERROR actualizando eclass."
LANG_UPDATING_PACKAGESLIST="\n""$WHITE""Actualizando lista de paquetes...""$NO_COLOUR""\n"
LANG_OPTIMIZING_LIBRARIES="Optimizando acceso a librerías""\n"
LANG_NUM_PACKAGES_AVAILABLE="$WHITE""%s""$NO_COLOUR"" paquetes disponibles"

LANG_UPDATINGPORTAGE="$WHITE""Actualizando portage...""$NO_COLOUR"

LANG_FAILED_CHECKLDDDOWNLOAD="\nNo se pudo descargar la herramienta check-ldd, disculpe, no se puede continuar. Verifique si tiene acceso a esta URL:
		\n\n%s"

LANG_NOTINSTALLED="no instalado"
LANG_INSTALLED="instalado"
LANG_PACKAGE="Paquete"
LANG_INFODEPENDENCIES="Dependencias necesarias (no instaladas):"
LANG_TESTING="Probando..."
LANG_PACKAGEOMITED="$WHITE""%s omitido$NO_COLOUR\n"

LANG_PACKAGEREMOVED="$WHITE""%s ha sido desinstalado.$NO_COLOUR"

LANG_INCORRECTPARAMETERS="Parámetros incorrectos."
LANG_PACKAGENOTFOUND="No se encuentra el paquete..."
LANG_INSTALLING="Instalando"

LANG_INSTALLINGKERNEL="$BEEP $WHITE Instalando un kernel!$NO_COLOUR\n"
LANG_INSTALLINGORIGINALSCRIPT="Se ejecutará el script original generado por el Kit de Desarrollo de UTUTO: /admin/repository/scripts/%s.sh"
LANG_INSTALLINGINSECONDS="$WHITE Instalando paquetes en 9 segundos...$NO_COLOUR\n (Ctrl-C para cancelar)"
LANG_PACKHASBEENINSTALLED="$WHITE %s ha sido instalado en su sistema.$NO_COLOUR"

LANG_VERIFYINGDEPS="Verificando dependencias..."
LANG_PACKAGEALREADYINSTALLED="$WHITE El paquete seleccionado ya está instalado en su sistema.$NO_COLOUR"
LANG_ALREADYINSTALLED="ya está instalado"

LANG_PACKAGESTOBEINSTALLED="$WHITE Se instalará los siguientes paquetes:$NO_COLOUR"
LANG_CONFIRMCONTINUE="Continuar? [Y|n]: "

LANG_ALLBINARIESDOWNLOADED="$WHITE Todos los paquetes binarios han sido descargados... $NO_COLOUR"
LANG_GO="Acción!"

LANG_PACKHASBEENED="$WHITE""Para el paquete  %s se ha completado la acción requerida  %s en su sistema.$NO_COLOUR"

LANG_ERRORDNSPKG="ERROR: No se pudo encontrar el servidor pkg.ututo.org, compruebe que su conexión está bien y que el DNS está funcionando correctamente."
LANG_WARNDNSPKGPROXY="ATENCION: no se pudo consultar al DNS pero usted parece tener un servidor proxy, la instalación continuará de todos modos, pero tenga en cuenta que existe una mínima probabilidad de falla"

LANG_EMERGEFAILED="ATENCION: la instalación normal de $WHITE""%s$NO_COLOUR falló.\n"
LANG_UNTARAFTERFAILEDEMERGE="\nIntentaremos corregir la instalación de manera forzada, frecuentemente esto soluciona el problema.\n Si no desea forzar la instalación puede cancelar esta acción y la instalación continuará con el siguiente paquete."
LANG_CONFIRMORCANCEL="Confirma? (presione n para cancelar) [$WHITE""Y$NO_COLOUR/n]"

LANG_RUN_PRELINK="Quiere ejecutar prelink ahora? Este proceso optimizará el acceso a las librerías del sistema pero puede demorar varios minutos."

LANG_CHECKLDDINBACKGROUND="\n------------------\n${WHITE}* NOTA:${NO_COLOUR} check-ldd y prelink se ejecutarán en segundo plano durante algunos minutos, por favor ${WHITE}permita que terminen su trabajo sin interrumpirlos, de lo contrario algunas liberías y programas podrían dejar de funcionar.${NO_COLOUR} Si esto sucediera, ejecute 'uget verify' para ejecutar check-ldd y prelink en primer plano.\n\nSI EL SOFTWARE QUE ACABA DE INSTALAR NO FUNCIONA, ESPERE A QUE TERMINE DE EJECUTARSE check-ldd${BEEP}\n------------------\n"
LANG_CHECKLDCOMPLETE="ATENCION: se completó la ejecución en segundo plano de check-ldd"
LANG_SEARCHING="Buscando"
LANG_SELECT_PACKAGESEARCH="Varias opciones coinciden con su selección:"
LANG_PACKAGEEMERGE="Buscando en portage... espere"
