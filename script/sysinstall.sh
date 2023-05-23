#!/bin/sh
#
# DLD - Deutsche Linux Distribution
# Copyright 1993, 1994 D.Haaga Hard- und Software, Stuttgart, Germany
# All rights reserved.
#
# Redistribution and use of this script, with or without modification, is 
# permitted provided that the following conditions are met:
#
# 1. Redistributions of this script must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
#  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
#  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
#  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO
#  EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
#  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
#  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
#  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#
# sysinstall is a front-end to tar/compress that allows packages (tar archives,
# optionally compressed)  to be installed, removed, or files to be extracted 
# into packages from disk.  It also will execute the script /install/doinst.sh
# if found in the package, with one of the following args: -install (install 
# files), -remove (uninstall package), -extract (move files to locations in
# preparation for extraction), and -retract (move files back after
# an extract has been done).  
#
# requires:  tar, sed, basename, compress/zcat/gzip, mv, mount and umount.
# Original: Softlanding Software, 1992
#
#

umask 0
InstDevice="/dev/fd0"
InstMountDir="/mnt"

DestRootDir="/"
VolumesDir=""
InstallKey=
InstallWithOneKey=
UserPrompt=
GlobalUserPrompt=
Packer="gzip"
Decrypt="dldkey"
ArchivExt="tgz"

clear="c"
revon="[7m"
revoff="[27m"
#DEBUG="true"
InstallScript="doinst.sh"

declare -i stat=0


function PrintUsage() {
cat << THEEND
$clear
        DLD - Deutsche Linux Distribution V1.1.1c Installationsprogramm

Gebrauch:
	sysinstall [Optionen] {Befehl} [Paket] ...

  Optionen:
     -doprompt            * auf Benutzerbestaetigung warten
     -instkey <key>       * Installationsschluessel angeben
     -instdev <instdev>   * Installation erfolgt von Geraet <instdev>
     -instroot <instroot> * Installation erfolgt in das Verzeichnis <instroot>
     -instsrc <instsrc>   * Archive im Verzeichnis <instsrc> suchen 

  Befehl:
     -install <pkg>.[tgz|tpz|taz|tar]  * installiert das Archiv <pkg>

     -remove <pkg>               * deinstalliert ein Archiv

     -disk                       * installiert die Archive auf der Diskette in
                                 * Laufwerk A:

     -volume <diskname>          * installiert den Diskettensatz <diskname>

     -volumes <set1> [set2] ..   * installiert die angegebenen Diskettensaetze
 
     -view                       * listet alle installierten Archive

THEEND
}

function bye() {
	cd /
#	umount -a  1> /dev/null 2> /dev/null
#	mount -t proc none /proc
	umount $InstMountDir 1> /dev/null 2> /dev/null
	echo -e "\a\n"
	echo "Die Installation wurde abgebrochen."
	echo
	exit 1
}

trap bye 2


function debug()
{
	if [ -n "$DEBUG" ]; then
		echo -n "debug: "
		echo $@
	fi
}


function clearVars() {
	LogDir=$DestRootDir/install
	LogDirPackages=$LogDir/packages
	LogDirScripts=$LogDir/scripts
	LogDirContents=$LogDir/disk_contents
	LogDirInfoFiles=$LogDir/infofiles
	LogDirVolumes=$LogDir/volumes
	LogInfoFile=$LogDirInfoFiles/infofile.inf

	if [ -n "$__german" ]; then
		InfoFileExtension=".ger"
	else
		InfoFileExtension=".eng"
	fi

	UserPrompt=$GlobalUserPrompt
	InfoFile=
	SkipDisk=
	VolumeInfoFile=
	Volume=
	VolumeNr=
	mountType=msdos
	volumes=""
	if [ -z "$InstallWithOneKey" ]; then
		InstallKey=
	fi
}



function makeLogDirs() {
	if [ ! -d $LogDir ]; then
		mkdir $LogDir
	fi
	if [ ! -d $LogDirPackages ]; then
		mkdir $LogDirPackages
	fi
	if [ ! -d $LogDirScripts ]; then
		mkdir $LogDirScripts
	fi
	if [ ! -d $LogDirContents ]; then
		mkdir $LogDirContents
	fi
	if [ ! -d $LogDirInfoFiles ]; then
		mkdir $LogDirInfoFiles
	fi
	if [ ! -d $LogDirVolumes ]; then
		mkdir $LogDirVolumes
	fi
}


function ShowInstalled() {
	local i

	for i in $LogDirPackages/*; do
		echo "$i"
	done;
}


function printSeparator() {
	declare -i  i=0

	while [ 0 ]; do
		echo -n "----"
		i=i+1
		if [ $i = 20 ]; then
			break;
		fi
	done
	echo
}

function userWait()  {
      echo -n "Weiter mit [return]: "
      read ans
}

function RemovePkg() {
	if [ -f $LogDirPackages/$1 ]; then
		if [ -f $LogDirScripts/$1 ]; then
			(cd $DestRootDir; sh $LogDirScripts/$1 -remove;)
			rm $LogDirScripts/$1
		fi
		(cd $DestRootDir; xargs /bin/rm -f ) < $LogDirPackages/$1 
		rm $LogDirPackages/$1
	else
		echo "Fehler: unbekanntes Paket $1"
	fi
}


#
# MountDisk ( diskname | directory )
#
# return code:  0 = no error
#		1 = skip
#		2 = quit
#		
#
function MountDisk() {
	local k
	local ans

	declare -i MountStat

	debug "Mount Disk $1"
	if [ "$VolumesDir" != "" ]; then
		if [ -d $VolumesDir/$1 ]; then
			stat=0
			return 0
                else
			echo "Fehler: \"$VolumesDir/$1\" nicht gefunden."
			stat=2
			return 2
		fi
	fi

	while [ 1 ]; do
		if [ -n "$DEBUG" ]; then
			debug "Inside MountDisk: Unmounting"
			cd /; echo "umount $InstMountDir" | sh
		else
			cd /; echo "umount $InstMountDir" | sh 1> /dev/null 2> /dev/null
		fi

		echo -e "\a"
		if [ "$1" != "" ]; then
			echo "Legen Sie die Diskette => $1 <= ein und betaetigen Sie [return] oder"
		else
			echo "Legen Sie die Diskette ein und betaetigen Sie [return] oder"
		fi

		echo '  "s" um diese Diskette zu ueberspringen oder'
		echo "  \"q\" zum Ueberspringen des Diskettensatzes => $Volume <=."
		echo -n "Eingabe (return/s/q) [return]: "
		read ans
		if [ "$ans" = "" ]; then
			ans="y"
		fi

		if [ "$ans" = "s" ]; then
			stat=1
			return 1
		elif [ "$ans" = "q" ]; then
			stat=2
			return 2
		elif [ "$ans" != "y" ]; then
			echo "Falsche Eingabe!"
			continue
		fi

		MountStat=0
		for k in $mountType msdos minix ext2; do
			if [ $MountStat = 0 -o $k != $mountType ]; then
				debug "mount -r -t $k $InstDevice $InstMountDir  1> /dev/null 2> /dev/null"
				mount -r -t $k $InstDevice $InstMountDir  1> /dev/null 2> /dev/null
				MountStat=$?
				debug "MountStat = $MountStat"

				if [ $MountStat = 0 ]; then
					mountType=$k
					stat=0
					return 0
				fi
			fi
		done

		echo
		echo "Fehler: die Diskette konnte nicht gemountet werden."
	done
}


function UnmountDisk() {
	debug "UmountDisk called. VolumesDir: $VolumesDir"
	if [ "$VolumesDir" = "" ]; then
		debug "Umounting now: $InstMountDir"
		sync
		if [ -n "$DEBUG" ]; then
			debug "Inside UnmountDisk: Unmounting"
			cd /; echo "umount $InstMountDir" | sh
		else
			cd /; echo "umount $InstMountDir" | sh 1> /dev/null 2> /dev/null
		fi
	fi
}

# ShowInfo( ArchveFile, FileExt )
# returns 0
#
#
function ShowInfo() {
	local ArchivFile=`basename $1 .$2`
	local FileExt=$2
	local Priority=""
	local PACKAGE_SIZE


	debug "Showinfo: $1, $2"
	echo
	printSeparator

        if [ "$InfoFile" != "" ]; then
		Priority=`(grep "^$ArchivFile:[ ]*\(ADD\|REC\|OPT\|SKP\)") < $InfoFile`
	fi

	if `echo $Priority | grep "ADD" > /dev/null` ; then
		Priority="[Erforderlich]"
	elif `echo $Priority | grep "REC" > /dev/null` ; then
		Priority="[Empfehlenswert]"
	elif `echo $Priority | grep "OPT" > /dev/null` ; then
		Priority="[Optional]"
	elif `echo $Priority | grep "SKP" > /dev/null` ; then
		Priority="[Nicht notwendig]"
	else Priority="[Unbekannt]"
	fi

	echo "Archiv Name: ==>$ArchivFile<==        Prioritaet: $Priority"

        if [ "$InfoFile" != "" ]; then
		echo "Archiv Beschreibung:"
		(grep "^$ArchivFile:" | \
		grep -v "^$ArchivFile:[ ]*\(ADD\|REC\|OPT\|SKP\)") \
		< $InfoFile

		grep "^$ArchivFile:" $InfoFile >> $LogDirContents/$VolumeNr
		if [ $? = 0 ]; then
			echo "" >> $LogDirContents/$VolumeNr
		fi
	fi

	echo
	if [ "$FileExt" = "tgz" ]; then
		COMPBYTES="`gzip -l $SourcePath/$ArchivFile.tgz | tail -1 | cut -b1-9`"
		UNCOMPBYTES="`gzip -l $SourcePath/$ArchivFile.tgz | tail -1 | cut -b10-19`"
		COMPRESSED="`expr $COMPBYTES / 1024` KByte"
		UNCOMPRESSED="`expr $UNCOMPBYTES / 1024` KByte"
		echo "Groesse komprimiert: $COMPRESSED, Groesse unkomprimiert: $UNCOMPRESSED."
	elif [ "$FileExt" = "tar" ]; then
		PACKAGE_SIZE=`filesize $SourcePath/$ArchivFile.tar`
		echo "Dieses unkomprimierte Archiv belegt `expr $PACKAGE_SIZE / 1024`KByte."
	fi
}

function getInstallKey() {
	declare -i  keystat

	cat << EOF

Zur Installation des Paketes "$Volume" ist ein Aktivierungsschluessel erforderlich.
EOF
	while [ 1 ]; do
		echo -n "Aktivierungsschluessel: "
		read ans

		dldkey -k $ans < /dev/null 2> /dev/null
		if [ "$?" != 0 ]; then
			echo "Der Aktivierungsschluessel ist nicht gueltig."
			echo -n "Nochmal eingeben (j/n)? [j] "
			read ans
			if [ "$ans" = "" ]; then ans="j"; fi
			if [ "$ans" = "j" -o "$ans" = "J" ]; then
				continue
			else
				stat=1
				return 1
			fi
		fi
		InstallKey=$ans
		break
	done
	stat=0
	return 0
}

# InstallPkg( archiveFile, archiveFileExt )
# returns:	0 = no error
#		1 = error
#
function InstallPkg() {
	if [ ! -f $1 ]; then
		echo "Archivfile \"$1\" nicht gefunden."
		return 1
	fi

	PackageName=`basename $1 .$2`

	echo "Installiere..."
	rm -f $LogDir/$InstallScript

	case "$2" in
		"tar") 
			(cd $DestRootDir; tar -xvlpf - | sed "/\/$/d" ) \
			 < $1 > $LogDirPackages/$PackageName;;
		"tgz")
			if [ "$PackageName" = "devs" ]; then
				(cd $DestRootDir; rm -rf dev)
			fi
			(cd $DestRootDir; $Packer -dc | tar -xvlpf - | sed "/\/$/d" ) \
			 < $1 > $LogDirPackages/$PackageName;;
		"tgc")
			if [ -z "$InstallKey" ]; then
				getInstallKey
				if [ "$stat" != 0 ]; then
					return 1
				fi
			fi
			(cd $DestRootDir; $Decrypt -k $InstallKey | $Packer -dc \
                        | tar -xvlpf - | sed "/\/$/d" ) < $1 > $LogDirPackages/$PackageName;;
	esac

	if [ -f $LogDir/$InstallScript ]; then
		(cd $DestRootDir; sh $LogDir/$InstallScript -install;)
		mv $LogDir/$InstallScript $LogDirScripts/$PackageName;
	fi

	# Now we reload the shell hash table in case we've added something useful
	# to the command path:
	hash -r
	echo "Fertig."

	return 0
}


# searchInfoFile()
# returns: 0 = infofile found
# returns: 1 = infofile not found
#
function searchInfoFile()  {
	local allInfoFile
	local found="true"
	local i

	debug "searchInfoFile1: $SourcePath/$Volume$InfoFileExtension $VolumeNr"

	for i in $InfoFileExtension .ger .eng .inf; do
		if [ -z "$found" -a $i = $InfoFileExtension ]; then
			continue
		fi

		found=
		if [ -f $SourcePath/$VolumeNr$i -o \
		     -f $SourcePath/disk$VolumeNr ]; then
			found="true"
			InfoFileExtension=$i
			break
		fi
	done

	debug "searchInfoFile4: InfoFileExtension=$InfoFileExtension"

	if [ -z "$found" ]; then
		stat=1
		return 1
	fi

	if [ -n "$VolumeInfoFile" ]; then
		stat=0
		return 0		# infofile is valid for whole volume
	fi

        allInfoFile=$SourcePath/$Volume$InfoFileExtension

	if [ -f $allInfoFile ]; then
		rm -f $LogInfoFile
		cp -p $allInfoFile $LogInfoFile
		InfoFile=$LogInfoFile
		VolumeInfoFile="true"
		stat=0
		return 0
	elif [ -f $SourcePath/$VolumeNr$InfoFileExtension ]; then
		InfoFile=$SourcePath/$VolumeNr$InfoFileExtension
		stat=0
		return 0
	elif [ -f $SourcePath/disk$VolumeNr ]; then
		InfoFile=$SourcePath/disk$VolumeNr
		stat=0
		return 0
	fi

	InfoFile=
	stat=1
	return 1
}


# getInfoFile()
# returns: 0 = infofile found
# returns: 1 = infofile not found
#
function getInfoFile()  {
	debug "Get Info File $1"
	if [ "$VolumesDir" = "" ]; then
		SourcePath=$InstMountDir	 # install from device
	else
		SourcePath=$VolumesDir/$VolumeNr # install from mounted disk
	fi


	if [ "$VolumeNr" = "" ]; then
		stat=0
		return 0	# single disk
	fi

	searchInfoFile

	debug "Search Info File returns $stat. Infofile is $InfoFile."
	if [ "$stat" = 0 ]; then
		return 0
	else
		echo 'Fehler: Das Infofile konnte nicht gefunden werden.'
		echo 'Ist die richtige Diskette eingelegt?'
		echo 'Nochmal probieren mit "n", ueberspringen mit "s" und'
		echo -n 'abbrechen mit "q" (n/s/q) [n]: '
		read  ans

		if [ "$ans" = "n" ]; then
			stat=3
			return 3
		elif [ "$ans" = "s" ]; then
			stat=1
			return 1
		elif [ "$ans" = "q" ]; then
			stat=2
			return 2
		else
			stat=3
			return 3
		fi
	fi
}


# queryInstall(  archiveFile, archiveFileExt )
# returns:	0 = no error
#		1 = error
#
function queryInstall()  {
	local package
	local first="true"

	debug "queryInstall: $1 $2"
	package=`basename $1 .$2`
	while [ 0 ]; do
		if [ -n "$first" ]; then
			ShowInfo $1 $2
		fi
		first=

		cat << EOF

Wollen Sie das Paket => $package <= installieren?

  [y] - Ja
  [n] - Nein
  [v] - Archivinfo nochmal anzeigen
  [f] - Freien Festplattenplatz anzeigen
  [a] - Automatische Installation der restlichen Disketten dieses Satzes
  [s] - Restliche Disketten ueberspringen

EOF

		echo -n 'Eingabe (y/n/v/f/a/s) [y]: '
		read ans
		if [ "$ans" = "" ]; then
			ans="y"
		fi

		case "$ans" in
			"f")  printSeparator
			      df
			      printSeparator
			      userWait
			      continue;;
			"n")  echo -e "\a"
			      echo "Ueberspringe Paket $package."
			      echo
			      return 0;;
			"s")  echo -e "\a"
			      echo "Ueberspringe Rest der Diskette."
			      SkipDisk="true"
			      return 0;;
			"v")  ShowInfo $1 $2
			      printSeparator
			      userWait
			      continue;;
			"a")  UserPrompt=
			      return 0;;
			"y")  InstallPkg $1 $2
		              return 0;;
			*) echo "Ungueltige Eingabe."
		esac
	done
}


# InstallDisk( VolumeNr )
# returns:	0 = disk installed
#		1 = skip disk (disk not installed)
#		2 = last disk installed or quit
#
function InstallDisk() {
	local FileExt
	local ArchivFile

	VolumeNr=$1

	debug "Install Disk $VolumeNr. Source Path: $SourcePath"
	MountDisk $VolumeNr
	if [ "$stat" != 0 ]; then
		return $stat
	fi

	getInfoFile
	stat=$?

	debug "getInfoFile returns $stat"
	if [ "$stat" != 0 ]; then
		UnmountDisk
		return $stat
	fi

	for FileExt in tgz tgc tar; do
		for ArchivFile in $SourcePath/*.$FileExt; do
			if [ "$ArchivFile" = "$SourcePath/*.$FileExt" ]; then
				continue;
			fi

			if [ -n "$UserPrompt" ]; then
				queryInstall $ArchivFile $FileExt
			else
				ShowInfo $ArchivFile $FileExt
				InstallPkg $ArchivFile $FileExt
			fi

			if [ -n "$SkipDisk" ]; then
				break
			fi
		done
		if [ -n "$SkipDisk" ]; then
			break
		fi
	done

	SkipDisk=
	if [ -f "$SourcePath/install.end" ]; then
		debug "install.end found"
		stat=2
	else
		stat=0
	fi

	UnmountDisk
	return $stat
}

#  InstallVolume( Volume )
#  returns:  0 = no error
#            1 = error
#
function InstallVolume() {
	declare -i counter=1

	clearVars

	Volume=$1
	echo "Volume $Volume is installed" > $LogDirVolumes/$Volume
	while [ 0 ]; do
		InstallDisk $1$counter
		debug "Install Disk: $?"

		if [ "$stat" = 1 ]; then
			echo "Ueberspringe Diskette $1$counter..."
		elif [ "$stat" = 2 ]; then
			debug "Last disk found."
			return 2	#  Quit
		elif [ "$stat" = 3 ]; then
			continue	#  Try again
		fi

		counter=$counter+1;
	done

	return $stat
}

function InstallSingleDisk() {
	declare -i stat=0

	clearVars

	InstallDisk
	stat=$?
	return $stat
}



# -------------------     main program     ----------------- 

#  get options
while [ 0 ]; do
	if [ $# -le 1 ]; then
		break;
	fi

	case "$1" in
		"-instdev")
			InstDevice=$2
			shift 1;;
		"-instroot")
			DestRootDir=$2
			shift 1;;
		"-doprompt")
			export __prompt="true"
			GlobalUserPrompt="true";;
		"-instsrc")
			VolumesDir=$2
			shift 1;;
		"-instkey")
			InstallKey=$2
			InstallWithOneKey="true"
			shift 1;;
		*)  break;
	esac

	shift 1
done


clearVars

# get command
case $# in
	1)
	case $1 in
		"-disk")
			makeLogDirs
			InstallSingleDisk;;

		"-view")  ShowInstalled;;
		*) PrintUsage;;
	esac
	;;

	2)
	case $1 in
		"-remove")  RemovePkg $2;;
		"-volume"|"-volumes")
			makeLogDirs
			InstallVolume $2;;

		"-install")
			makeLogDirs
			if [ "`basename $2 .$ArchivExt`" != "`basename $2`" ]; then
				InstallPkg $2 $ArchivExt
		   	elif [ "`basename $2 .tar`" != "`basename $2`" ]; then
				InstallPkg $2 tar
			elif [ "`basename $2 .tgc`" != "`basename $2`" ]; then
				InstallPkg $2 tgc
			else  echo "Fehler: Unbekannte Fileendung des Archives"
		        fi
			;;


		*)  PrintUsage;;
	esac
	;;

	*)
	case $1 in
		"-volumes")
			makeLogDirs
			shift 1
			volumes="$*"
			for i in $volumes; do
				InstallVolume $i
			done
			;;

		*) PrintUsage;;
	esac
esac
