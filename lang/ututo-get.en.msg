#!/bin/bash
# ututo-get.en.msg - shell script
#
# Autor: Pablo Manuel Rizzo <info@pablorizzo.com>
# Traduced by: Adrián A. Ramírez <enarxe@gmail.com>
#
# Copyright (C) 2004 - 2007 The UTUTO Project
# Distributed under the terms of the GNU General Public License v3 or new
#
# $Header: $

LANG_IMPORTANT_NOTICE_GLIBC="--------------------------------------------------------------------------------
¡ATENTION! Read Carefully:


You ""$WHITE""must update the GLIBC package before installing another software. In this way:

$WHITE ututo-get install glibc $NO_COLOUR

Note for desktop users (NO SERVER USERS): if you use graphic interface using Xorg,
after updating GLIBC ""$WHITE""you must""$NO_COLOUR"" update Xorg: 

$WHITE ututo-get install xorg $NO_COLOUR

--------------------------------------------------------------------------------"

LANG_SINTAX_BASIC="Sintax: ""$WHITE""uget <Action> [package]
	$NO_COLOUR""Action:
	""$WHITE""<package>
		""$NO_COLOUR""Download and install last version of <package>
	""$WHITE""install
		""$NO_COLOUR""List, download and install versions of <package>
	""$WHITE""installpkg
		""$NO_COLOUR""Install binary <package>. May be tbz2 (Gentoo), txz (Slackware), deb (Debian-based) or rpm (RedHat-based)
	""$WHITE""update
		""$NO_COLOUR""Update the packages list and some system scripts 
	""$WHITE""xs-update
		""$NO_COLOUR""Update all packages to new version availables (This process may take much time)
	""$WHITE""install
		""$NO_COLOUR""Download and install <package>
	""$WHITE""reinstall
		""$NO_COLOUR""Download and reinstall <package> and all its dependencies (though they were already installed)
	""$WHITE""fixdepend
		""$NO_COLOUR""Download and install any dependencies of <package> that was not installed or a new version of them
	""$WHITE""remove
		""$NO_COLOUR""Uninstall <package>
	""$WHITE""info
		""$NO_COLOUR""Show information about <package>
	""$WHITE""download
		""$NO_COLOUR""Download (but do not install) <package>  and all dependencies not installed or outdated
	""$WHITE""fastinstall
		""$NO_COLOUR""Download and install <package> but without verifying nor installing dependencies (Be careful, this can damage your system)
	""$WHITE""fastreinstall
		""$NO_COLOUR""Download and reinstall <package> but without verifying nor installing dependencies (Be careful, this can damage your system)
	""$WHITE""verify
		""$NO_COLOUR""Verify and install missing libraries of the system
	""$WHITE""autoupgradeuget
		""$NO_COLOUR""If there is a new version of ututo-get, download and install it
	""$WHITE""dist-upgrade
		""$NO_COLOUR""Upgrade $SYSTEMNAME2 to new version available (This process may take much time)
	""$WHITE""skel
		""$NO_COLOUR""Upgrade $SYSTEMNAME2 system skel to new version
	""$WHITE""skelinstall
		""$NO_COLOUR""Upgrade $SYSTEMNAME2 system skel to new version and reconfigure system and users to use it
	""$WHITE""search
		""$NO_COLOUR""List packages according to search patron in $SYSTEMNAME2
	""$WHITE""category
		""$NO_COLOUR""List packages in specific category in $SYSTEMNAME2
	""$WHITE""changelog
		""$NO_COLOUR""View details of last changes in $SYSTEMNAME2
	""$WHITE""cpu
		""$NO_COLOUR""View details of hardware and system
	""$WHITE""develkit
		""$NO_COLOUR""Install Devel Kit for $SYSTEMNAME2
"

LANG_DOWNLOADING="downloading"
LANG_DONE="done"
LANG_FAILED="failed"
LANG_DOWNSKEL="Downloading and installing new skel"
LANG_BINERROR="Binary format not recognized"
LANG_FIXING="Fixing configuration files and users"
LANG_NOTFOUND="not found."
LANG_PROFILE="Profile"
LANG_SKELPREVINST="Skel previously installed"
LANG_IMPORTKEYS="Importing keys"
LANG_REMOVING="Removing package"

LANG_CHECK_VERSION_UTUTOGETSH="Verifying version of ututo-get [%s]..."
LANG_CHECK_VERSION_UTUTOGETCONF="Verifying version of ututo-get.conf..."
LANG_CHECK_VERSION_UTUTOGETKMDR="Verifying version of ututo-get.kmdr..."
LANG_CHECK_VERSION_UTUTOGETDESKTOP="Verifying version of ututo-get.desktop..."
LANG_CHECK_VERSION_UTUTOGETMSG="Verifying version of %s..."
LANG_UTUTOGETSH_NEWVERSION="There is a new version of ututo-get "
LANG_UTUTOGET_WILLUPGRADE="ututo-get will auto-upgrade now..."
LANG_CHECK_VERSION_REPOSITORY="Verifying new packages in the repository [$REPOSITORIO]..."
LANG_UPDATING_CHECKLDD="Updating check-ldd..."
LANG_UPDATING_CHECKLDD_FAILED="\nNo se pudo descargar la herramienta check-ldd. Installation will abort now. 
Please, verify the acces to this URL:
		\n\n $CHECKLDD_URL"

LANG_SELECT_PROCESSOR="Please, select your processor type (if you are not sure, select \"i686\"):"
LANG_SELECTED_PROCESSOR="Processor %s selected"
LANG_NO_PROCESSOR="Failed to select the type of processor. Unable to continue. $BEEP"

LANG_SELECT_LAST_PACKAGE="\nThere are several versions available in this package, you are probably looking for this one: ""$WHITE""%s""$NO_COLOUR"" $BEEP
Do you want  yo install this version? (Enter "no" to see for another disponible versions)\n"
LANG_INSTALL_DEFAULT="Install ""$WHITE""%s""$NO_COLOUR""? [""$WHITE""Y""$NO_COLOUR""|n]: "

LANG_SELECT_PACKAGE="\nSeveral options match with your selecion.\n""$WHITE""Please, select a package to install:""$NO_COLOUR"""
LANG_CANCELEDBYUSER="Operation aborted by the user."

LANG_GPG_OK="Status: Signatures of packages OK"
LANG_GPG_ERROR="Error verifiying signatures of the package"
LANG_GPG_NOTFOUNDREQUIRED="$WHITE Could not find the  package \"%s.tbz2\". This package is required and installation will abort now.$NO_COLOUR"
LANG_GPG_CONTINUEDOWNLOAD="Continue installing the other packages? [Y|n]: "
LANG_GPG_NOTFOUNDCANCELLING="File not found %s.tbz2. Installation will abort now."
LANG_GPG_RESTARTINSTALLATION="Error:Some files could not be verified. Please, restart the installation to try downloading them again."
LANG_GPG_REPORT="Please, report this bug to $WHITE""http://bugs.ututo.org""$NO_COLOUR. Copy and send the following lines to the Developers Team of Ututo:"


LANG_OMITINGCUPSPOSTINSTALL="$WHITE #### OMITING Post-installation tasks for  %s #### $NO_COLOUR \n"
LANG_POSTINSTALLTASKS="$WHITE #### Post-installation tasks for  %s #### $NO_COLOUR \n Please wait..."
LANG_INSTALLINGPACKAGE="\nInstalling: ""$WHITE""%s""$NO_COLOUR\n"
LANG_PROCESSINGICONS="Processing icons..."
LANG_PROCESSINGINFOFILES="Processing info-files..."
LANG_REMOVINGOLDPACKAGES="Removing old packages..."
LANG_PROCESSINGLIBRARIES="Processing libraries..."

LANG_UPDATEINPROGRESS="$WHITE""Updating in progress...""$NO_COLOUR\n"
LANG_UPDATING_ECLASS="$WHITE""Updating eclass...""$NO_COLOUR"
LANG_UPDATING_ECLASS_ERROR="Error updating eclass."
LANG_UPDATING_PACKAGESLIST="\n""$WHITE""Updating the packages list...""$NO_COLOUR""\n"
LANG_OPTIMIZING_LIBRARIES="Optimizing access to libraries""\n"
LANG_NUM_PACKAGES_AVAILABLE="$WHITE""%s""$NO_COLOUR"" available packages"

LANG_FAILED_CHECKLDDDOWNLOAD="\nCould not download check-ldd tool. Installation  will abort now. Verify the access to thisURL:
		\n\n%s"

LANG_NOTINSTALLED="not installed"
LANG_INSTALLED="installed"
LANG_PACKAGE="Package"
LANG_INFODEPENDENCIES="Not installed required dependencies:"
LANG_TESTING="Testing..."
LANG_PACKAGEOMITED="$WHITE""%s omitted$NO_COLOUR\n"

LANG_PACKAGEREMOVED="$WHITE""%s has been uninstalled.$NO_COLOUR"

LANG_INCORRECTPARAMETERS="Incorrect parameters."
LANG_PACKAGENOTFOUND="Package not found..."
LANG_INSTALLING="Installing"

LANG_INSTALLINGKERNEL="$BEEP $WHITE Installing the kernel $NO_COLOUR\n"
LANG_INSTALLINGORIGINALSCRIPT="Installing the script generated by the original kit developing of UTUTO: /admin/repository/scripts/%s.sh"
LANG_INSTALLINGINSECONDS="$WHITE Installing packages in nine seconds...$NO_COLOUR\n (Press Ctrl-C to cancel)"
LANG_PACKHASBEENINSTALLED="$WHITE %s has been installed in your system.$NO_COLOUR"

LANG_VERIFYINGDEPS="Verifying dependencies..."
LANG_PACKAGEALREADYINSTALLED="$WHITE The selected package is already installed in your system.$NO_COLOUR"
LANG_ALREADYINSTALLED="is already installed"

LANG_PACKAGESTOBEINSTALLED="$WHITE The following packages will be installed:$NO_COLOUR"
LANG_CONFIRMCONTINUE="Continue? [Y|n]: "

LANG_ALLBINARIESDOWNLOADED="$WHITE All binarý packages has been donloaded... $NO_COLOUR"
LANG_GO="Now!"

LANG_PACKHASBEENED="$WHITE""For the package  %s has been completed the required action  %s in your system.$NO_COLOUR"

LANG_RUN_PRELINK="Do you want to run prelink now? It will optimize access to shared libraries"

LANG_CHECKLDDINBACKGROUND="\n------------------\n${WHITE}* NOTE:${NO_COLOUR} check-ldd and prelink will run in the background for a few minutes, please ${WHITE}let them finish properly or some libraries an programs might stop working.${NO_COLOUR} In this case, run 'uget verify' to run check-ldd and prelink in foreground.\n\nIF THE SOFTWARE DON'T WORK, PLEASE WAIT FOR check-ldd TO FINISH${BEEP}\n------------------\n"
LANG_CHECKLDCOMPLETE="ATENTION: check-ldd have finished"
LANG_SEARCHING="Searching"
LANG_SELECT_PACKAGESEARCH="Several options match with your selecion:"
LANG_PACKAGEEMERGE="Serching in portage... please wait"
