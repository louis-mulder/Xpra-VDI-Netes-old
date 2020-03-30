#!/bin/bash
# 
# No changes on next lines are needed 
# Begin ###########################################
#
OPTION=`echo ${1:-'--buildimages=no'}| sed -e 's/./\l&/g'` 
case ${OPTION} in
#(
 --buildimages=no | buildimages=no |\
 --buildimages=yes | buildimages=yes ) 
   TOBUILD=`IFS=\= ; set -- ${OPTION} ; echo ${2}` ;export TOBUILD
;;
#(
* )
   echo  Usage: `basename ${0}` with building images --buildimages=yes
   echo '        without omit option or use --buildimages=no'
   exit 1
;;
esac
#
#
# Louis Mulder March. 2020
#
# Deploy a Kubernetes base VDI environment on cluster
# Below there are some variables to fill-in or to change
# depending on your situation.
#
# Script is provided as it is.
#
# Check if you are running as root on the master
#
# Xpra is released under the terms of the GNU GPL v2, or, at your option, any
# later version. See the file COPYING for details.
#
MASTER_IP_ADDR="`exec 2> /dev/null; kubectl cluster-info|grep -i master| sed -e 's%^.*//%%' -e 's%:.*$%%'`"
#
if ! ip a | grep "${MASTER_IP_ADDR}" 1> /dev/null 2>&1 || \
    [ `id | sed -e 's/^.*=//' -e 's/(.*$//'` != 0 ]
then
   MASTER_NAME=`set -- \`getent hosts ${MASTER_IP_ADDR}\` ; echo ${2}`
   echo "You must run `basename ${0}` as root on server ${MASTER_NAME:-'???'} with ip ${MASTER_IP_ADDR}"
   exit 1
fi
DISTNAME='vdi-dist' ; export DISTNAME
PROG=${0}
BPROG=`basename ${PROG}`
DPROG=`dirname ${PROG}`
ABS_PATH=`(cd ${DPROG}; pwd)`
export PROG
case ${ABS_PATH} in
#(
     /*/${DISTNAME}/* ) 
        ( echo "You must first copy the content of `dirname ${ABS_PATH}`"
          echo "to new directory ending in directory-name which will be used as a"
          echo "new NAMESPACE name. Then go to this directory/deploy and"
          echo "adjust xpra-proxy.sh, and run it with ./xpra-proxy.sh from this position"
        ) 1>&2
        exit 1
;;
esac
#
# Don't remove next 3 lines !!!!
OLDENV="`set | sed -e 's/=.*$//' -e '/^'"'"'/d'\
                   -e 's%^%/^%' -e 's%$%/d%'`" # Don't remove this lines !!!!
export OLDENV
# End ###########################################
#
# BEGINVARS Don't remove this line !!!!
# Inventory where the user sessions may run.
#
# If XPRA_WORKERS is empty or has the value all (lower or uppercase)
# No labeling will take place and session may run everywhere.
# if it contains a list of servernames these servers will be labeled
# with xpra-worker=${NAMESPACE}
#
XPRA_WORKERS='CHANGEME'
#
export XPRA_WORKERS
#
XPRA_LOCAL_TIME=/usr/share/zoneinfo/Europe/Amsterdam 
#
# localtime zone setting 
# Must be an absolute path to the timezone
#
# If empty default zone = /usr/share/zoneinfo/Europe/Amsterdam
#
export XPRA_LOCAL_TIME
#
# Default namespace will be derived off the current directory, remove 'deploy' and
# take the basename of the result.
#
# Proxy Ingress server(s) will run in the namespace ingress-${NAMESPACE}
#
NAMESPACE="${NAMESPACE:-`basename \`dirname \\\`pwd\\\`\``}" ; export NAMESPACE
#
XPRA_DEPLOYNAME='xpra-proxy'; export XPRA_DEPLOYNAME
#
# TOPDIRS 
#
# Shared via a mount on the underlaying server (worker)
# 
# XPRA_TOPDIR_EXT == Full path of shared storage on the servers
#
# XPRA_TOPDIR_INT == mountpath in the pod/container
#
XPRA_TOPDIR_INT="${XPRA_TOPDIR_INT:-/srv}" ; export XPRA_TOPDIR_INT
XPRA_TOPDIR_EXT="${XPRA_TOPDIR_EXT:-`dirname \`pwd\``}"/to_container ; export XPRA_TOPDIR_EXT
#
# If XPRA_VAR_LOG_INT is not empty
# Hostpath ${XPRA_VAR_EXT/<POD-hostname>/. will be mounted on
# /var/log in the POD/Container.
# If it is the first time pod is started a initial setup will yake place
# by extracting tar-image /var/xpra/var.tmp comming from the container
# creation. (Dockerfile)
#
# Xpra-proxy server will be exposed as service 
# And will accessable by external ip-addresses
#
# Be sure that this address is configured as a VIP on a worker/master
# For HA use for example keepalived.
#
# Port-number 443 and for debugging 444 will be used.
#
EXTERNALIPS='CHANGEME'   # Fill in the addresses separated by a space
#
XPRA_VAR_LOG_INT="/var/log"
XPRA_VAR_LOG_EXT="${XPRA_TOPDIR_EXT}"'/log' ; export XPRA_VAR_LOG_EXT
#
# If session is specified as mhd-XXXXX. XXXX stands for example desktop, sseamless etc.
# A shared directory/storage will be mounted in the pod and will be used as
# placeholder for persitent homedirs.
#
# In case high-secured is desired remove all the sessions startups begginning with mhd-
# out of the directory ../session_types (seen from the current ../deploy directory.
#
VOLUME_HOMEDIRS_EXT="${VOLUME_HOMEDIRS_EXT:-/home}" ;export VOLUME_HOMEDIRS
VOLUME_HOMEDIRS_INT="${VOLUME_HOMEDIRS_INT:-/home}" ;export VOLUME_HOMEDIRS
#
# Image registry server
# Format FQDN:PORTNUMBER
#
XPRA_REGISTRY_SRV='CHANGEME:5000'
#
export XPRA_REGISTRY_SRV
# A default image must be specified and available
#
IMAGE_DEFAULT="${XPRA_REGISTRY_SRV}/vdi-xfce4" ;export IMAGE_DEFAULT
#
# Specific images per session type if desired.
#
IMAGE_ICEWM="${XPRA_REGISTRY_SRV}/vdi-icewm" ;export IMAGE_ICEWM
IMAGE_DESKTOP_OFFICE="${XPRA_REGISTRY_SRV}/vdi-office" ;export IMAGE_DESKTOP_OFFICE
IMAGE_SEAMLESS_OFFICE="${XPRA_REGISTRY_SRV}/vdi-office" ;export IMAGE_SEAMLESS_OFFICE
IMAGE_DESKTOP="${XPRA_REGISTRY_SRV}/vdi-xfce4" ;export IMAGE_DESKTOP
IMAGE_DSKTOP="${XPRA_REGISTRY_SRV}/vdi-xfce4" ;export IMAGE_DESKTOP
IMAGE_SEAMLESS="${XPRA_REGISTRY_SRV}/vdi-xfce4" ;export IMAGE_SEAMLESS
IMAGE_FIREFOX="${XPRA_REGISTRY_SRV}/vdi-browsers" ;export IMAGE_FIREFOX
IMAGE_CHROME="${XPRA_REGISTRY_SRV}/vdi-browsers" ;export IMAGE_CHROME
IMAGE_REMMINA="${XPRA_REGISTRY_SRV}/vdi-remmina" ;export IMAGE_REMMINA
IMAGE_XPRA_PROXY=${IMAGE_XPRA_PROXY:-"${XPRA_REGISTRY_SRV}/vdi-base"};export IMAGE_XPRA_PROXY
PRESTOP_CMD="${PRESTOP_CMD:-xpra stop}" ; export PRESTOP_CMD
#
# Certificates
# Accessing the xpra-proxy with websocket etc. must be done on a secure way !!
#
# Place the cert. files in ../ssl
#
SSL=on
SSL_CERT=/etc/xpra/ssl/server.crt
SSL_KEY=/etc/xpra/ssl/server.key
#
# If XPRA_DEMO_USERS=Y and on the .../etc directory the files
# demousers-passwd and demousers-shadow are available
# these files will be appended in the pod in /etc/passwd and
# /etc/shadow
#
# Format is the same as for shadow and passwd
#
# With a useradd and chpasswd a existing passwd/shadow can be append
# in the first stage. With a copy/paste insert the created demo-users
# in demousers-passwd and ---shadow.
#
# default added a demouser-passwd/--shadow with xpra-user01--05 and
# a simple password 'only4now'
#
XPRA_DEMO_USERS=Y
export XPRA_DEMO_USERS
#
#
# Domainname (DNS)
#
DOMNAME="${DOMNAME:-CHANGEME}"
#
# Sessions using IDM/IPA
# If IDM_DOMAIN = empty only the 
# local passwd file will be used to determine
# the users UID/GID and validating
# Idm/Freeipa is also installed in the session-pods
#
# See also the variable SESSION_USING_IDM
# If you using for large amounts of users be sure you have 
# more freeipa/IDM servers.
# If users has a 2 factor auth. The pam_auth xpra-module cannot
# handle this. 
# But: If a OTP is found in the users credentials the user needs 
# only this as password for validation. See also the pam service
# xpra. The standard generated OTP will not work because it length 
# is too long (key), it is not compatible with the oath pam-module.
# How to work around is as follows:
#
# Install the packages gen-oath-safe and oathtool
# Generate a token and use the key as key input for freeipa/IDM server
# during the creation of a token for a user.
#
# Example:
# Generate key with
#  on the shell-prompt:
#    gen-oath-safe  totp
#
# INFO: Bad or no token type specified, using TOTP.
# INFO: No secret provided, generating random secret.
# 
# Key in Hex: 7b43210b0d981195b5e68875eb1f94b28d6a6103
# Key in b32: PNBSCCYNTAIZLNPGRB26WH4UWKGWUYID (checksum: 8)
# 
# URI: otpauth://totp/totp?secret=PNBSCCYNTAIZLNPGRB26WH4UWKGWUYID
#
# <DISPLAY OF THE QR-CODE>
#                                                               
# users.oath / otp.users configuration:
# HOTP/T30 totp - 7b43210b0d981195b5e68875eb1f94b28d6a6103
#
# take the string: PNBSCCYNTAIZLNPGRB26WH4UWKGWUYID paste it in
# keyfield of the popup of the OTP-window or use it as 
# option value when creating a user with the CLI of ipa/idm.
#
# The script used by PAM /bin/pre-auth.sh searches the
# LDAP environment for the OTP of a user and place it in /etc/oath/users.oath
# The pam-module pam_oath.so will look in this file.
#
# It works for the tcp_auth option and when you are using ssh as transport-channel.
# However by using ssh you need give two times a OTP. In most cases you need
# generate the OTP twice.
#
# For generating a OTP use FreeOtp or on a Linux command prompt you can generate
# the OTP with oathtool
# For example:
# oathtool -w0 --totp -b PNBSCCYNTAIZLNPGRB26WH4UWKGWUYID
#
# And will give you the otp as output -- 683205
#  
# Using: websocket or ssl (creates a ssl-tunnel between the proxy-server and your workplace)
#
#  Obtaining the ca-certificate can be done by first logging in with a browser
#  and exporting the certificate.
#
#  xpra attach wss://....@srvname:portnr/session-type --ssl-ca-certs=<CA Cert file>
#
#  xpra attach ssh://....@srvname:portnr/session-type 
#  If a OTP is created in the ipa/idm environment you need to generate a OTP 2 times.
#
#  Xpra will allow you to use a plain in the clear data transmission !
#
# In most cases the ipa/idm domainame is equal to the DNS-domainname
# If not change the line below or when NOT using ipa/idm set the variable
# to empty
#
IDM_DOMAIN="${IDM_DOMAIN:-${DOMNAME}}" ; export IDM_DOMAIN
# IDM_DOMAIN="" ; export IDM_DOMAIN
#
# IDM_ADMIN_PASSWORD, password of dirsrv specified as base64 
# string
# Example: On the prompt
#          echo -n changeMe | base64
#          And take the result.
#
#  Don't forget the '-n' argument of echo
#
IDM_ADMIN_USER=${IDM_ADMIN_USER:-'YWRtaW4='} ; export IDM_ADMIN_USER
IDM_ADMIN_PASSWORD='b25seTRub3c=' ; export IDM_ADMIN_PASSWORD
#
XPRA_VALIDATE_USER='Y' ; export XPRA_VALIDATE_USER
XPRA_AUTH_METHOD="${XPRA_AUTH_METHOD:-pam:service=xpra}" 
#
# if SESSION_USING_IDM=Y and IDM_DOMAIN is NOT empty idm/Freeipa will be 
# configured in the session-pod of the user
# if SESSION_USING_IDM=N and IDM_DOMAIN is NOT empty idm/Freeipa will be 
# not installed in the session-pod. Idm/Freeipa will be activated only in
# the XPRA proxy server. User uid/gid information will be provided but passing
# a Env. variable to the session-pod.
# 
SESSION_USING_IDM='N' ; export SESSION_USING_IDM
#
# Ip address(es) where the service xpra-proxy can be accessed
# from outside the cluster.
# Portnumber on the outside is 443
# Proxy instance will be exposed internally with 8443
#
# For debugging purposes:
# First set replicas on 1
# and jump in the pod with kubectl -n ${NAMESPACE} exec -it pod-instance-name bash
# On the prompt run:
# /srv/debug_444/start_proxy_8444
# If ${XPRA_TOPDIR_INT} = /srv
# And use port number 444 to access from outside.
# examples:  Browser https://srvname:444/seamless
# From the commandline  xpra wss://usename[:password]@srvname:444
#
#
# Shared scratch directory
#
#
# ${XPRA_SCRATCH_EXT}/tmp will be mounted in the pod
# as ${XPRA_TOPDIR_INT}/tmp and is read/writeable like /tmp 
# Users can change files etc. between them.
#
# However if it is forbidden to copy in or out data from
# underlying server(s) set it to N
#
XPRA_SCRATCH_EXT=${XPRA_TOPDIR_EXT}/scratch/tmp ;export XPRA_SCRATCH_EXT
#
# If next variables contains an external directory
# Sockets and Status of Xpra will outside the container
# available. (Probably future use)
#
XPRA_STATUS_DIR=${XPRA_TOPDIR_INT}/xpra-status ; export XPRA_STATUS_DIR
XPRA_SOCKET_DIR=${XPRA_TOPDIR_INT}/xpra-socket ; export XPRA_SOCKET_DIR
#
# Number of proxy-instances initial
# For explanation see the Kubernets documentation
#
REPLICAS=1
#
# Default xpra has a maximum of 100 concurrent connections
# To overrule with XPRA_MAX_CONCURRENT_CONNECTIONS
#
XPRA_MAX_CONCURRENT_CONNECTIONS=${XPRA_MAX_CONCURRENT_CONNECTIONS:-1024}
#
export XPRA_MAX_CONCURRENT_CONNECTIONS
#
# Special settings XPRA and waiting times (sleep)
#
# Don't change unless you know what you are doing....
#
SECRET_NAME_PROXY="${XPRA_DEPLOYNAME}-certs" ; export SECRET_NAME_PROXY
SECRET_NAME_CERTS="${SECRET_NAME_PROXY}" ; export SECRET_NAME_CERTS
SECRET_NAME_KUBE="${XPRA_DEPLOYNAME}-kube"  ; export XPRA_DEPLOYNAME
#
XPRA_STARTUP_PROXY="${XPRA_TOPDIR_INT}/bin/startup_proxy.sh ${XPRA_TOPDIR_INT}/bin/start_or_get_pod.sh"
# XPRA_STARTUP_PROXY="/bin/sleep 7200" # Startup proxy for debugging etc. Pod will startup only with a sleep of 7200 sec.
PRE_STOP_CMD="/usr/bin/xpra stop"
LIVENESS_PROBE_CMD="${XPRA_TOPDIR_INT}/bin/health_check_xpra-proxy.sh"
PORT="${PORT:-14500}" ;export PORT
#
XPRA_SERVER_CRT="${XPRA_TOPDIR_EXT}/../ssl/server.crt"
XPRA_SERVER_KEY="${XPRA_TOPDIR_EXT}/../ssl/server.key"
#
VOLUME_SRVDIR="${XPRA_TOPDIR_EXT}"      ; export VOLUME_SRVDIR
VOLUME_SSLDIR="${XPRA_TOPDIR_EXT}"'/ssl'; export VOLUME_SSLDIR
#
EMPTYDIR="/tmp/em${$}ty" export EMPTYDIR
#
SECRET_NAME_IDM=""
[ "${IDM_DOMAIN}" != '' ] && \
   SECRET_NAME_IDM="join-idm-`echo ${IDM_DOMAIN}| sed -e 's/\./-/g'`"
export SECRET_NAME_IDM
#
export SSL SSL_CERT SSL_KEY DOMNAME
export XPRA_SERVER_CRT XPRA_SERVER_KEY
#
# Be sure directories are available
#
[ "${XPRA_SCRATCH_EXT}" != '' -a ! -d "${XPRA_SCRATCH_EXT}" ] && mkdir -p ${XPRA_SCRATCH_EXT} 2> /dev/null
#
if [ -d "${XPRA_SCRATCH_EXT}/." ]
then
   chown root:root ${XPRA_SCRATCH_EXT}
   chmod 700 `dirname ${XPRA_SCRATCH_EXT}`
   chown root:root ${XPRA_SCRATCH_EXT}
   chmod 1777 ${XPRA_SCRATCH_EXT}
fi

[ "${XPRA_VAR_LOG_EXT}" != '' -a ! -d "${XPRA_VAR_LOG_EXT}" ] && mkdir -p "${XPRA_VAR_LOG_EXT}"
[ ! -d "${XPRA_TOPDIR_EXT}/save-states/." ] && mkdir -p  "${XPRA_TOPDIR_EXT}/save-states"

#
# Source general SHELL functions
#
#

if [ -f "${XPRA_TOPDIR_EXT}/etc/xpra-functions.sh" ]
then
  . "${XPRA_TOPDIR_EXT}/etc/xpra-functions.sh"
else
 echo "Can't find file ${XPRA_TOPDIR_EXT}/etc/xpra-functions.sh"  1>&2
 exit 3
fi
#
# Example outcome of construct_volumes kubemaster01:/export/data:/data:/data/srv/vdi-nfs/to_container
#
NFSMOUNT=`construct_volumes  ${XPRA_TOPDIR_EXT}`
 eval `IFS=\: ; set -- ${NFSMOUNT}
                FQDN=\`nslookup ${1} | \
		   sed -e '/[Nn][Aa][Mm][Ee].*:/!d' -e 's/[Nn][Aa][Mm][Ee].*://' -e 's/[\t ]*//g'\`
                echo "XPRA_NFS_SERVER_SRVDIR=${FQDN:-${1}}; export XPRA_NFS_SERVER_SRVDIR"
                echo "XPRA_TO_MOUNT_SRVDIR=${2}\`echo ${4} | sed -e 's%'"${3}"'%%'\` ; export XPRA_TO_MOUNT_SRVDIR" `

NFSMOUNT=`construct_volumes  ${VOLUME_HOMEDIRS_EXT}`
 eval `IFS=\: ; set -- ${NFSMOUNT}
                FQDN=\`nslookup ${1} | \
		   sed -e '/[Nn][Aa][Mm][Ee].*:/!d' -e 's/[Nn][Aa][Mm][Ee].*://' -e 's/[\t ]*//g'\`
                echo "XPRA_NFS_SERVER_HMEDIR=${FQDN:-${1}}; export XPRA_NFS_SERVER_HMEDIR"
                echo "XPRA_TO_MOUNT_HMEDIR=${2}\`echo ${4} | sed -e 's%'"${3}"'%%'\` ; export XPRA_TO_MOUNT_HMEDIR" `

#
# Generate mounts -- nfs or hostpaths and put this information in 2 files
# During creation of the session pod volumes/mountpaths will be added
# to the yaml stdout.
#
# Variable XPRA_VOLUMES contains all the volumes used by session-pod.
# Variable XPRA_VOLUMES_MOUNTS contains the volume-mounts.
# 
cd ${XPRA_TOPDIR_EXT}/../to_mount
#
# Subdir .../to_mount contains symbolic pointing to directories which must be mounted
# in session-pod.
# If a symbolic link is in the top of the to_mount the pointing directory will be mounted in 
# in the top of pod. (root)
# Example:
# a symlink mybin_ro is pointing to ../to_container/mybin --> mounted in pod on /mybin
# Last part is _ro means mount it readonly, _rw means read/write
#
# If subdir is specified as variable naam:
#
# .../to_mount/XPRA_TOPDIR_INT/bin_ro -> ../../to_container/bin
#
# An evaluation in the shell will take place of the string XPRA_TOPDIR_INT
# mountpoint in the session-pod will be: 
#
# eval ${XPRA_TOPDIR_INT}/bin --> content of variable XPRA_TOPDIR_INT = /srv so
# Mount the external source on /srv/bin with option readonly in the pod.
#
# With a regular file with the same name on the same directory level a condition
# can be added. For example mount the external source yes or no.
# For example if it is not permitted to use the users homedir. User homedir will be only
# only mounted if XPRA_USER_MHD = Y, each other value will be treated as No.
#
# Example: .../to_mount/home_rw -> /home, file ..../to_mount/home_rw.if contains
# [ "${XPRA_MHD}" = MHD -a "${VOLUME_HOMEDIRS_INT}" != '' -a "${VOLUME_HOMEDIRS_EXT}" != '' ]
# Filename is same as symbolic link with extension '.if' !
#
# Variable XPRA_MHD will set to NHD if XPRA_USER_MHD=N, if it is Y then mounting the homedir is
# depending on the session-name .....:443/desktop will mount not the home-dir, if ../mhd-desktop as
# session name is used the users homedir will be mounted under /home/<username>.
#
# This initial setup based on NFS sharing so be aware every worker which will be used must know
# the ip-address of NFS-servers where the source id exported. (Proper /etc/hosts files or DNS)
#
# Function get_mounts is using the symbolic links in .../to_mount and deeper to figure out where the
# source is coming from. If it is not a NFS-mount it assumes the shared filesystem is on the same
# way mounted on the level of filesystem of the worker-node. (Eg. glusterfs)
# After processing it fills the variable STRINGS with yaml code. Each line in this variable
# starting with 'VL' will be written to .../protected/hostpaths. 'VM' will be written to
# .../.../protected/mountpaths. During pod-creation (see spawnpod in .../etc/xpra-functions.sh) these 
# files will be included, inclusive created if statements derived from the founded XXX_YY.if files.
#
# If a variable starts with the string XPRA_ it will be exported and will be included in the
# file ..../to_container/etc/xpra-vars.sh. 
# Adding a variable run always in .../deploy xpra-proxy.sh. If you run more replicas of the 
# xpra-proxy server adjust the parameter REPLICAS=XXX to the current count of proxy servers. Otherwise
# a number of users sessions will be disconnected and a number of xpra-proxy pods will be killed !
# 
XPRA_USER_MHD='Y' ;export XPRA_USER_MHD
#  
XPRA_VOLUMES='      ' ;export XPRA_VOLUMES
XPRA_VOLUMES_MOUNTS='      ' ;export XPRA_VOLUMES_MOUNTS
#
STRINGS="`get_mounts`"
#
mkdir -p ${XPRA_TOPDIR_EXT}/../protected 2> /dev/null
echo "${STRINGS}" | egrep '^VL' | sed -e 's/^VL//'  > ${XPRA_TOPDIR_EXT}/../protected/hostpaths
echo "${STRINGS}" | egrep '^VM' | sed -e 's/^VM//'  > ${XPRA_TOPDIR_EXT}/../protected/mountpaths
chmod 400 ${XPRA_TOPDIR_EXT}/protected/hostpaths ${XPRA_TOPDIR_EXT}/../protected/mountpaths
chmod 500 ${XPRA_TOPDIR_EXT}/../protected 
unset STRINGS
cd - > /dev/null 2>&1
#
export XPRA_VOLUMES XPRA_VOLUMES_MOUNTS
#
generate_xpra_proxy () { #  Don't remove this line and must be begin at column 0 !!!
#
(
XPRA_MODE='proxy'
cat <<EOB
kind: Namespace
apiVersion: v1
metadata:
  name: ingress-${NAMESPACE}
  labels:
    name: ingress-${NAMESPACE}
---
kind: Namespace
apiVersion: v1
metadata:
  name: ${NAMESPACE}
  labels:
    name: ${NAMESPACE}
`if [ "${IDM_DOMAIN}" != '' ]
then
echo '---'
echo 'apiVersion: v1'
echo 'kind: Secret'
echo 'metadata:'
echo '  name: "'"${SECRET_NAME_IDM}"'"'
echo '  namespace: '"ingress-${NAMESPACE}"
echo 'data:'
echo '  dirsrv-password: "'"${IDM_ADMIN_PASSWORD}"'"'
echo '  idm-admin-password: "'"${IDM_ADMIN_PASSWORD}"'"'
echo '  idm-admin-user: "'"${IDM_ADMIN_USER}"'"'
echo 'type: Opaque'
echo '---'
echo 'apiVersion: v1'
echo 'data:'
echo '  idm-admin-user: "'"${IDM_ADMIN_USER}"'"'
echo '  idm-admin-password: "'"${IDM_ADMIN_PASSWORD}"'"'
echo 'kind: Secret'
echo 'metadata:'
echo '  name: '"${SECRET_NAME_IDM}"
echo '  namespace: '"${NAMESPACE}"
echo 'type: Opaque'
fi`
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: ${XPRA_DEPLOYNAME}
  name: ${XPRA_DEPLOYNAME}
  namespace: ingress-${NAMESPACE}
spec:
  externalIPs:
`for ip in ${EXTERNALIPS}
do
echo "  - ${ip}"
done`
  externalTrafficPolicy: Cluster
  ports:
  - port: 443
    protocol: TCP
    targetPort: 8443
  selector:
    app: ${XPRA_DEPLOYNAME}
  type: NodePort
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: ${XPRA_DEPLOYNAME}
  name: ${XPRA_DEPLOYNAME}-444
  namespace: ingress-${NAMESPACE}
spec:
  externalIPs:
`for ip in ${EXTERNALIPS}
do
echo "  - ${ip}"
done`
  externalTrafficPolicy: Cluster
  ports:
  - port: 444
    protocol: TCP
    targetPort: 8444
  selector:
    app: ${XPRA_DEPLOYNAME}
  type: NodePort
---
apiVersion: v1
kind: ConfigMap
metadata:
    name: xpra-env
    namespace: ingress-${NAMESPACE}
data:
   SESSION_USING_IDM: "${SESSION_USING_IDM}"
   POD_FROM_NAMESPACE: "ingress-${NAMESPACE}"
   SRC_PORTS: "8443"
   PASSWD_ENTRY: "${PASSWD_ENTRY}"
   SSL: "${SSL}"
   SSL_CERT: "${SSL_CERT}"
   SSL_KEY: "${SSL_KEY}"
   GROUP_ENTRIES: "${GROUP_ENTRIES}"
   SECRET_NAME_CERTS: "${SECRET_NAME_CERTS}"

`for var in \`set | sort -u | sed -e '/\(^[Xx][Pp][Rr][Aa]_[A-Za-z0-9_][A-Za-z0-9_]*\)\(=\)\(..*\)/!d' \
                                -e 's/=.*$//'\`
do
   eval echo '\ \ \ '"${var}"': \"''$'"${var}"'\"'
done`
   
`if [ "${IDM_DOMAIN}" != '' ]
then
echo '   IDM_DOMAIN: "'"${IDM_DOMAIN}"'"'
echo '   USE_OTP_PW: "'"${USE_OTP_PW}"'"'
echo '   NAMESPACE: "'"${NAMESPACE}"'"'
fi`
`if [ "${PROXY_DEBUG}" != '' ]
then
echo 'PROXY_DEBUG: "'"${PROXY_DEBUG}"'"'
fi`
---
apiVersion:  apps/v1
kind: Deployment
metadata:
  name: ${XPRA_DEPLOYNAME}
  namespace: ingress-${NAMESPACE}
  labels:
    app: ${XPRA_DEPLOYNAME}
spec:
  replicas: ${REPLICAS}
  selector:
    matchLabels:
      app: ${XPRA_DEPLOYNAME}
  template:
    metadata:
      labels:
        app: ${XPRA_DEPLOYNAME}
    spec:
      containers:
      - name:  ${XPRA_DEPLOYNAME}
        image: "${IMAGE_XPRA_PROXY:-${IMAGE_DEFAULT}}"
        securityContext:
          capabilities:
             add: ["NET_ADMIN", "SYS_TIME","CAP_SYS_ADMIN","SYS_ADMIN"]
        command: ["/bin/bash","-c" ]
        args: ["${XPRA_STARTUP_PROXY}"]
        envFrom:
        - configMapRef:
            name: xpra-env
        lifecycle:
          preStop:
            exec:
              # SIGTERM triggers a quick exit; gracefully terminate instead
              command: ["/bin/bash", "-c", "${PRE_STOP_CMD}"]
        livenessProbe:
            initialDelaySeconds: 90
            periodSeconds: 30
            timeoutSeconds: 20
            failureThreshold: 15
            exec:
               command:
               - "${LIVENESS_PROBE_CMD}"
        volumeMounts:
        - mountPath: ${XPRA_TOPDIR_INT}
          name: srv-dir
        - mountPath: ${XPRA_TOPDIR_INT}/protected
          name: protected-dir
        - mountPath: ${XPRA_TOPDIR_INT}/tmp
          name: srv-tmp
        - mountPath: /etc/oath
          name: users-oath
        - mountPath: /sys/fs/cgroup
          name: sys-fs-cgroup
          readOnly: true
        - mountPath: /dev/shm
          name: dshm

`if [ "${IDM_DOMAIN}" != '' ]
then
echo '        - mountPath: /etc/join-idm-'\`echo "${IDM_DOMAIN}"| sed -e 's/\./-/g'\`
echo '          name: join-idm-'\`echo "${IDM_DOMAIN}"| sed -e 's/\./-/g'\`
echo '          readOnly: true'
fi`
        - mountPath: `(IFS=\:;set -- \`getent passwd root\`; echo ${6})`/.kube
          name: ${SECRET_NAME_KUBE}
          readOnly: true
`if [ "${SECRET_NAME_CERTS}" != '' ]
then
echo '        - mountPath: /etc/xpra/ssl/crt'
echo '          name: "'"${SECRET_NAME_CERTS}-crt"'"'
echo '          readOnly: true'
echo '        - mountPath: /etc/xpra/ssl/key'
echo '          name: "'"${SECRET_NAME_CERTS}-key"'"'
echo '          readOnly: true'
fi`
      volumes:
      - name: sys-fs-cgroup
        hostPath:
         path: /sys/fs/cgroup
         type: Directory
      - name: dshm
        emptyDir:
          medium: Memory
      - name: protected-dir
        nfs:
          server: "${XPRA_NFS_SERVER_SRVDIR}"
          path: "${XPRA_TO_MOUNT_SRVDIR}/../protected"
      - name: users-oath
        nfs:
          server: "${XPRA_NFS_SERVER_SRVDIR}"
          path: "${XPRA_TO_MOUNT_SRVDIR}/etc/oath"
      - name: srv-dir
        nfs:
          server: "${XPRA_NFS_SERVER_SRVDIR}"
          path: "${XPRA_TO_MOUNT_SRVDIR}"
      - name: srv-tmp
        nfs:
          server: "${XPRA_NFS_SERVER_SRVDIR}"
          path: "${XPRA_TO_MOUNT_SRVDIR}/scratch/tmp"

`if [ "${IDM_DOMAIN}" != '' ]
then
echo '      - name: "'"${SECRET_NAME_IDM}"'"'
echo '        secret:'
echo '            secretName: "'"${SECRET_NAME_IDM}"'"'
echo '            defaultMode: 256'
fi`
      - name: "${SECRET_NAME_KUBE}"
        secret:
          secretName: "${SECRET_NAME_KUBE}"
          defaultMode: 256
`if [ "${SECRET_NAME_CERTS}" != '' ]
then
echo '      - name: "'"${SECRET_NAME_CERTS}-key"'"'
echo '        secret:'
echo '           secretName: "'"${SECRET_NAME_CERTS}-key"'"'
echo '           defaultMode: 256'
echo '      - name: "'"${SECRET_NAME_CERTS}-crt"'"'
echo '        secret:'
echo '           secretName: "'"${SECRET_NAME_CERTS}-crt"'"'
echo '           defaultMode: 292'
fi`
`if [ "${XPRA_WORKERS}" != '' -o "\`echo "${XPRA_WORKERS}" | sed -e 's/./\l&/g'\`" != 'all' ]
then
echo '      nodeSelector:'
fi`
      restartPolicy: Always
EOB
) 
}


node_labeling() {
  
   for srv in ${XPRA_WORKERS}
   do
     kubectl label nodes  ${srv} "xpra_run_${NAMESPACE}"'=true'  --overwrite=true
   done
}

do_some_hardening() {
  
 [ ${XPRA_TOPDIR_EXT} != '' -a -d ${XPRA_TOPDIR_EXT}/. ] && chmod 755 ${XPRA_TOPDIR_EXT}/.

 EXCLUDE=`basename ${XPRA_TOPDIR_EXT}`

 for dir in ${XPRA_TOPDIR_EXT}/../*
 do
   if [ -d "${dir}"/. -a "`basename ${dir}`" != "${EXCLUDE}" ]
   then
       chown root:root "${dir}"/. 
       chmod 700 "${dir}"/. 
   fi
 done
 if [ "${XPRA_SCRATCH_EXT}" != '' ]
 then
    [ "{XPRA_SCRATCH_EXT}" != '' -a ! -d `dirname "${XPRA_SCRATCH_EXT}"`/. ] && mkdir -p "${XPRA_SCRATCH_EXT}"
    chmod 700 `dirname "${XPRA_SCRATCH_EXT}"`/.
    chmod 1777 "${XPRA_SCRATCH_EXT}"/.
 fi
 if [ "${XPRA_STATUS_DIR}" != '' ]
 then
    SRC_PTH="${XPRA_TOPDIR_EXT}/`basename ${XPRA_STATUS_DIR}`"
    [ ! -d "${SRC_PTH}" ] && mkdir -p "${SRC_PTH}"
    chmod 1777 "${SRC_PTH}"
 fi
 if [ "${XPRA_SOCKET_DIR}" != '' ]
 then
    SRC_PTH="${XPRA_TOPDIR_EXT}/`basename ${XPRA_SOCKET_DIR}`"
    [ ! -d "${SRC_PTH}" ] && mkdir -p "${SRC_PTH}"
    chmod 1777 "${SRC_PTH}"
 fi
 [ "${SRC_PTH}" != '' ] && unset SRC_PTH
}

generate_xpra_vars_sh () {
#
# unset all shell functions
#
cat <<EOB
#!/bin/sh
#
#--------------------------------------------------------------------------------#
# Lines below may change depending on your Caas/Openshift/Kubernetes environment #
# Don't remove the if statement with corresponding fi statement. When script     #
# is starting up under UID 0 (root) it will switch over to non-root user.        #
# (${RUNADUSER})                                                                 #
# Starting up a Pod with be done with the user as specified in the variable      #
# USERNAME_RUNASUSER. Be sure this user has a ${HOME}/.kube directory containing #
# a valid config readable file. (Copy of the kubemaster /etckubernetes/admin.conf#
#                                                                                #
# Louis Mulder 2020                                                              #
# Xpra is released under the terms of the GNU GPL v2, or, at your option, any    #
# later version. See the file COPYING for details.                               #
#--------------------------------------------------------------------------------#
#
EOB
(
for fnc in `declare -F | sed 's/.* //'`
do
  unset "${fnc}"
done
unset fnc
set | sed -e '{
                '"${OLDENV}"'
                /^[A-Za-z0-9_].*[Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd].*$/d
                /^[Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd].*$/d
                /^[Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd].*$/d
                /\/\^/d
                /^'"'"'/d
                /^[Pp][Ii][Pp][Ee][Ss][Tt][Aa][Tt][Uu][Ss]=.*/d
                /^[Ff][Uu][Nn][Cc][Nn][Aa][Mm][Ee]/d
                /^_=/d
		s/\(^[A-Za-z_]\)\([0-9A-Za-z_]*\)\(=\)\(.*$\)/\1\2\3\4 ; export \1\2/
              }'
)
}

gen_namespaces_certs_secrets () {
#
SSLDIR_TMP=/tmp/ssl${$}
mkdir -p  ${SSLDIR_TMP}
cp ${XPRA_SERVER_KEY} ${SSLDIR_TMP}/.
cp ${XPRA_SERVER_CRT} ${SSLDIR_TMP}/.

if cd ${SSLDIR_TMP}
then
(
cat <<EOB
kind: Namespace
apiVersion: v1
metadata:
  name: ingress-${NAMESPACE}
  labels:
    name: ingress-${NAMESPACE}
---
kind: Namespace
apiVersion: v1
metadata:
  name: ${NAMESPACE}
  labels:
    name: ${NAMESPACE}
EOB
) | kubectl apply -f -
#
cat <<EOF >./kustomization.yaml
secretGenerator:
- name: ${SECRET_NAME_PROXY}-key
  namespace: ${NAMESPACE}
  files:
  - `basename ${XPRA_SERVER_KEY}`
EOF
kubectl apply -k .
sec_name="`kubectl -n ${NAMESPACE} get secrets | grep "${SECRET_NAME_PROXY}-key-"| sed -e 's/ *[Oo][Pp].*$//'| head -1`"
DATA="`kubectl -n ${NAMESPACE} get secrets "${sec_name}" -o yaml`"
#
for sec in ${NAMESPACE} ingress-${NAMESPACE}
do
   echo "${DATA}" |\
   sed -e '/[Kk][Ii][Nn][Dd].*[Ss][Ee][Cc][Rr][Ee][Tt]/,$d' \
       -e 's/^[Dd][Aa][Tt][Aa]/kind: Secret\nmetadata:\n   name: '"${SECRET_NAME_PROXY}-key"'\n   namespace: '"${sec}"'\ntype: Opaque\n&/'
   echo '---'
done | kubectl apply -f -
kubectl -n ${NAMESPACE} delete secrets "${sec_name}"
#
cat <<EOF >./kustomization.yaml
secretGenerator:
- name: ${SECRET_NAME_PROXY}-crt
  namespace: ${NAMESPACE}
  files:
  - `basename ${XPRA_SERVER_CRT}`
EOF
kubectl apply -k .
sec_name="`kubectl -n ${NAMESPACE} get secrets | grep "${SECRET_NAME_PROXY}-crt-"| sed -e 's/ *[Oo][Pp].*$//'| head -1`"
DATA="`kubectl -n ${NAMESPACE} get secrets "${sec_name}" -o yaml`"
#
for sec in ${NAMESPACE} ingress-${NAMESPACE}
do
   echo "${DATA}" |\
   sed -e '/[Kk][Ii][Nn][Dd].*[Ss][Ee][Cc][Rr][Ee][Tt]/,$d' \
       -e 's/^[Dd][Aa][Tt][Aa]/kind: Secret\nmetadata:\n   name: '"${SECRET_NAME_PROXY}-crt"'\n   namespace: '"${sec}"'\ntype: Opaque\n&/'
   echo '---'
done | kubectl apply -f -
kubectl -n ${NAMESPACE} delete secrets "${sec_name}"
#
unset DATA sec_name sec
fi
[ "${SSLDIR_TMP}" != '' -a -d  "${SSLDIR_TMP}"/. ] && rm -rf  "${SSLDIR_TMP}"
unset SSLDIR_TMP
}
gen_namespaces_kube_config_secrets() {
#
DIR_TMP=/tmp/kube${$}
mkdir -p  ${DIR_TMP}
KUBE_CONFIG=${KUBE_CONFIG:-/etc/kubernetes/admin.conf}
#
if [ -f ${KUBE_CONFIG} ]
then
   cp "${KUBE_CONFIG}" ${DIR_TMP}/config
else
   echo 'Are you on a kubemaster, no '${KUBE_CONFIG}' found' 1>&2
   [ "${DIR_TMP}" != '' -a -d "${DIR_TMP}" ] && rm -rf "${DIR_TMP}"
   exit 1
fi
if cd ${DIR_TMP}
then
(
cat <<EOB
kind: Namespace
apiVersion: v1
metadata:
  name: ingress-${NAMESPACE}
  labels:
    name: ingress-${NAMESPACE}
---
kind: Namespace
apiVersion: v1
metadata:
  name: ${NAMESPACE}
  labels:
    name: ${NAMESPACE}
EOB
) | kubectl apply -f -
#
cat <<EOF >./kustomization.yaml
secretGenerator:
- name: ${SECRET_NAME_KUBE}
  namespace: ingress-${NAMESPACE}
  files:
  - config
EOF
cp ./kustomization.yaml /var/tmp/kust2
kubectl apply -k .
sec_name="`kubectl -n ingress-${NAMESPACE} get secrets | grep "${SECRET_NAME_KUBE}-" | sed -e 's/ *[Oo][Pp].*$//'| head -1`"
DATA="`kubectl -n ingress-${NAMESPACE} get secrets "${sec_name}" -o yaml`"

sec=ingress-${NAMESPACE}
(
   echo "${DATA}" |\
   sed -e '/[Kk][Ii][Nn][Dd].*[Ss][Ee][Cc][Rr][Ee][Tt]/,$d' \
       -e 's/^[Dd][Aa][Tt][Aa]/kind: Secret\nmetadata:\n   name: '"${SECRET_NAME_KUBE}"'\n   namespace: '"${sec}"'\ntype: Opaque\n&/'
   echo '---'
) | kubectl apply -f -
kubectl -n ingress-${NAMESPACE} delete secrets "${sec_name}"
unset DATA sec_name sec
fi
[ "${DIR_TMP}" != '' -a -d  "${DIR_TMP}"/. ] && rm -rf  "${DIR_TMP}"
unset DIR_TMP
}
#
build_images () {
if cd `dirname ${XPRA_TOPDIR_EXT}`/images
then

 # Perform the base
 if cd vdi-base
 then
   sed -e 's/{{XPRA_REGISTRY_SRV}}/'"${XPRA_REGISTRY_SRV}"'/g' < Dockerfile.tmpl > Dockerfile
   docker build -t ${XPRA_REGISTRY_SRV}/vdi-base .
   docker push ${XPRA_REGISTRY_SRV}/vdi-base
 cd ..
 fi
 VDI_BUILDLIST=`echo vdi-* | sed -e 's/vdi-base//g'`
 for dir in ${VDI_BUILDLIST}
 do
 if cd ${dir}
 then
  sed -e 's/{{XPRA_REGISTRY_SRV}}/'"${XPRA_REGISTRY_SRV}"'/g' < Dockerfile.tmpl > Dockerfile
  docker build -t ${XPRA_REGISTRY_SRV}/${dir} .
  docker push ${XPRA_REGISTRY_SRV}/${dir}
  cd ..
 fi
 done
else
 echo "Huh no `dirname ${XPRA_TOPDIR_EXT}`/images directory....."
 exit 1
fi
}
#
TODO=`grep -n 'ADJUST' < ${PROG} | sed -e 's/=.*$//' -e '/^[0-9][0-9]*:TODO/d'`
if [ "${TODO}" != '' ]
then
 (
  for item in ${TODO}
  do
    eval `IFS=':' ; set -- ${item} ; echo "LINE=${1};VAR=${2}"`
    echo 'You need to adjust or give (a) values(s) for parameter '${VAR} at line ${LINE}
  done
  ) 1>&2
  exit 1
fi
#

if [ "${TOBUILD}" = 'yes' ] 
then
  echo Be patient this will take some time.....
  build_images
fi
gen_namespaces_certs_secrets
gen_namespaces_kube_config_secrets
generate_xpra_vars_sh > ${XPRA_TOPDIR_EXT}/etc/xpra-vars.sh
generate_xpra_proxy | tee ${XPRA_TOPDIR_EXT}/../yaml/xpra-proxy.yaml | kubectl apply -f -
do_some_hardening
node_labeling
#
