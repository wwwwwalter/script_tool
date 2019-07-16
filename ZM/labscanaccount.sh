#!/usr/bin/env bash
# in case bash is not in /bin
#  Version 	1.0	draft
#			1.1 support wget/curl/fetch
#			1.2 separate out error message between non ssh server vs permission error
#			1.3 prefer fetch on freebsd, do not create user if already exists
SCRIPTURL="http://isscorp.intel.com/IntelSM_BIgFix/33570/package/scan"

echo
# root only
if [[ $EUID -ne 0 ]]; then
	echo "Please run this script as root"
	exit 
fi

HOSTNAME=`hostname`
UNAME=`uname`

case $UNAME in 
"FreeBSD")
	echo "FreeBSD detected" 
	USERADDCMD="pw useradd sys_cert -m"
	
	# see which download tool we can use, try fetch with FreeBSD
	which fetch > /dev/null 2>&1
	if [[ $? -eq 0 ]]; then
		# probably only in FreeBSD		
		URLAPP='fetch'
	fi
	# otherwise prefer wget, which is also more widely available
	if [[ -z "$URLAPP" ]]; then
		which wget > /dev/null 2>&1
		if [[ $? -eq 0 ]]; then
			URLAPP='wget'
		fi
	fi
	if [[ -z "$URLAPP" ]]; then
		which curl > /dev/null 2>&1
		if [[ $? -eq 0 ]]; then
			# for some system curl has issue with default proxy setting in environment variable and --noproxy is not availabe with older curl, so set a workding value for this session
			no_proxy='.intel.com'		
			URLAPP='curl'
		fi
	fi
	
	;;	
"Linux")
	echo "Linux detected"
	USERADDCMD="useradd -m sys_cert"
	
	# see which download tool we can use, prefer wget, which is also more widely available
	which wget > /dev/null 2>&1
	if [[ $? -eq 0 ]]; then
		URLAPP='wget'
	fi
	if [[ -z "$URLAPP" ]]; then
		which curl > /dev/null 2>&1
		if [[ $? -eq 0 ]]; then
			# for some system curl has issue with default proxy setting in environment variable and --noproxy is not availabe with older curl, so set a workding value for this session
			no_proxy='.intel.com'		
			URLAPP='curl'
		fi
	fi
	if [[ -z "$URLAPP" ]]; then
		which fetch > /dev/null 2>&1
		if [[ $? -eq 0 ]]; then
			# probably only in FreeBSD		
			URLAPP='fetch'
		fi
	fi
	;;	
*)
	echo "Unknown system type, stop proceeding"
	exit 1
	;;
esac
	
if [[ -z "$URLAPP" ]]; then
	echo "unable to find a utility to download required parts, not wget, curl or fetch. Please review the review https://wiki.ith.intel.com/pages/viewpage.action?pageId=836603914 for alternatives"
	exit
else
	echo "will use $URLAPP to download required files"
fi



function DownloadToFile {
	# download from URL and save to path
	path=$2
	URL=$1
	RESULT=""
	
	case "$URLAPP" in 
	"wget")
		wget -4 -e use_proxy=no --no-check-certificate -O $path $URL > /dev/null 2>&1
		if [[ $? -ne 0 ]]; then RESULT="failed"; fi
		;;	
	"curl")
		curl -4 --noproxy "*" -k -o $path $URL > /dev/null 2>&1
		if [[ $? -ne 0 ]]; then RESULT="failed"; fi
		;;	
	"fetch")
		fetch -4 -d --no-verify-peer -o $path $URL > /dev/null 2>&1
		if [[ $? -ne 0 ]]; then RESULT="failed"; fi
		;;
	*)
		RESULT="failed"
		;;
	esac
}

function nopython {
	#echo "Python not installed or older than 2.7, try setup with bash"
	
	if [[ $BASH_VERSINFO[0] < 3 ]]; then
		echo "bash is too old, don't support regular expression"
		exit 
	fi
	
	passwdline=`getent passwd 2>/dev/null | grep -e "^sys_cert:"`
	if [[ -z "$passwdline" ]]; then
		# attempt to create user sys_cert
		$USERADDCMD > /dev/null 2>&1
		
		passwdline=`getent passwd 2>/dev/null | grep -e "^sys_cert:"`	
		if [[ -z "$passwdline" ]]; then
			echo "Failed to create/locate user sys_cert."
			exit
		fi
	else
		echo "user sys_cert already exists"		
	fi	
	
	echo $passwdline
    #sys_cert:x:1001:100::/home/sys_cert:/bin/bash
	IFS=':' read -a pswd <<< "$passwdline"
	USRID=${pswd[2]}
	GRPID=${pswd[3]}
	HOMEDIR=${pswd[5]}
	echo "User sys_cert is identifed as User ID: $USRID, Group ID: $GRPID, HOME DIR: $HOMEDIR"
	
	# if it's openssh
	if [ -f /etc/ssh/sshd_config ]; then
		echo "OpenSSH configuration detected"
		SSHDIR="$HOMEDIR/.ssh/"
		AUTHFILE="authorized_keys"
		
		#AuthorizedKeysFile .ssh/authorized_keys .ssh/authorized_keys2
		#AuthorizedKeysFile     %h/.ssh/authorized_keys
		#%h is replaced by the home directory of the user being authenticated, and %u is replaced by the username of that user.
		authline=`grep -e "^AuthorizedKeysFile" /etc/ssh/sshd_config`		 
		re="^AuthorizedKeysFile[[:space:]]+([^[:space:]]+/)([^[:space:]/]+)"
		if [[ "$authline" =~ $re ]]; then
			SSHDIR=${BASH_REMATCH[1]}
			AUTHFILE=${BASH_REMATCH[2]}
			SSHDIR=${SSHDIR/\%h/$HOMEDIR}
			SSHDIR=${SSHDIR/\%u/sys_cert}
			re="^\/"
			if ! [[ "$SSHDIR" =~ $re ]]; then
				#still not getting absolute path, guess %h is not specified
				SSHDIR="$HOMEDIR/$SSHDIR"
			fi					
		fi		
		
		echo "Create directory $SSHDIR"
		mkdir -p $SSHDIR > /dev/null 2>&1
		echo "Download public key configuration file"
		DownloadToFile $SCRIPTURL/authorized_keys $SSHDIR$AUTHFILE 
		echo "Restrict access to sys_cert and change ownership to sys_cert"
		chmod 700 $SSHDIR; chmod 600 $SSHDIR$AUTHFILE
		chown -R $USRID:$GRPID $SSHDIR > /dev/null 2>&1
	fi
	
	# if this is tactia/ssh2 server
	if [[ -f /etc/ssh2/sshd2_config ]]; then
		echo "Tactia/RSIT ssh configuration detected"
		SSHDIR="$HOMEDIR/.ssh2/"
		AUTHFILE="authorization"	
		
		#AuthorizationFile=%D/.ssh2/authorization
		#%U = user log-in name, %D = user's home directory, %IU = UID for user, %IG = GID for user
		authline=`grep -e "^AuthorizationFile=" /etc/ssh2/sshd2_config`
		
		re="^AuthorizationFile=([^[:space:]]+/)([^[:space:]/]+)"
		if [[ "$authline" =~ $re ]]; then
			SSHDIR=${BASH_REMATCH[1]}
			AUTHFILE=${BASH_REMATCH[2]}
			SSHDIR=${SSHDIR/\%D/$HOMEDIR}
			SSHDIR=${SSHDIR/\%U/sys_cert}
			SSHDIR=${SSHDIR/\%IU/$USRID}
			SSHDIR=${SSHDIR/\%IG/$GRPID}
			re="^\/"
			if ! [[ "$SSHDIR" =~ $re ]]; then
				#still not getting absolute path, guess %h is not specified
				SSHDIR="$HOMEDIR/$SSHDIR"
			fi

		fi		
		
		echo "Create directory $SSHDIR"
		mkdir -p $SSHDIR > /dev/null 2>&1
		echo "Download public key configuration file"
		DownloadToFile $SCRIPTURL/authorization $SSHDIR$AUTHFILE
		DownloadToFile $SCRIPTURL/infosec.ssh2.pub $SSHDIR"infosec.ssh2.pub" 
		echo "Restrict access to sys_cert and change ownership to sys_cert"
		chmod 700 $SSHDIR > /dev/null 2>&1; chmod 600 $SSHDIR$AUTHFILE $SSHDIR"infosec.ssh2.pub" > /dev/null 2>&1
		chown -R $USRID:$GRPID $SSHDIR > /dev/null 2>&1
	fi
	
	echo
	if [[ "$SSHDIR" = "" ]]; then
		echo "Failed to setup lab vulnerability scan account. Please check if ssh server is installed"
	else
		if [[ -f "$SSHDIR$AUTHFILE" ]]; then
			echo "Lab vulnerability scan account is setup successfully"
		else
			echo "Failed to setup lab vulnerability scan account. Please check if you have permission to create and write to $SSHDIR"
		fi
	fi
}


nopython
echo
exit 
