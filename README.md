# Xpra-VDI-Netes
Virtual Desktops under Kubernetes

How to deploy XPRA-VDI-NETES on a Kubernetes Cluster.

Requirements:

    1) A registry server.
    2) Shared storage between the nodes which are going to be used and the 
       kubernetes master.
    3) When using user-homedirectories be sure these are also
       shared along the cluster or at least on the nodes which are to
       going to be used for the deployment
    4) This setup is able to work with a IDM/FreeIpa environment. For demo-usage
       a parameter is involved to add some demo-users. They will be added to the
       local passwd-file of the proxy-server. (xpra-user01 -- xpra-user09)
    5) A number of container-images containing Xpra and X11 based applications.
    

Deployment:

    1) Untar the tar-ball on a shared storage of the K8-cluster you
       will get a sub-directory vdi-dist with files and scripts. This
       must be done on the master kube-controller !
       For the current setup use a NFS mounted directory from a NFS-server
       which also can be reached from the worker-nodes.
       Example: NFS-server has a exported directory with enough space. Mount this
       nfs-server:/export/.... /data. Create a sub-directory /data/srv and 
       untar the tar-ball. 
    2) Create on the same directory-level of vdi-dist a new directory
       where the name will be used as a namespace in the K8-cluster.
       ( Example: source /data/srv/vdi-dist
                  destination: /data/srv/vdi-stp )
    3) Jump into ../../new-directory (cd /data/srv/vdi-stp)
       Copy the whole vdi-dist directory to the destination.
       (Example: cd /data/srv/vdi-stp
                 (cd ../vdi-dist; tar cf - .) | tar xvf -
    4) Goto ..../vdi-stp.images/vdi-base and download with
       wget xz file centos-7-docker.tar.xz. URL:
       https://raw.githubusercontent.com/luxknight007/centos7/master/centos-7-docker.tar.xz. It should be
       also available in the other subdirectories ../vdi-xfce4 etc. The file is hardlinked to the other directories.
    4) Go to ...../vdi-stp/deploy and edit the script xpra-proxy.sh
    5) Edit the parameters which are now set to 'CHANGEME'
    6) If images are already builded perform from this directory,
          ./xpra-proxy.sh
       Or use ./xpra-proxy.sh --buildimages=yes
       With this option build the images and pushed to the 
       registry server. (Image names are the dirname of the directory
       where the Dockerfile resides)

Some remarks:

Deployment is tested with a insecure docker registry container. Be sure there
is enough free space in the mounted filesystem. Images may reach 3 - 3.5 Gb.

If a pod is scheduled to a K8 worker it may give a disconnect (timeout) because pulling a 
image take some time. With kubectl -n NAMESPACE get pod -o wide you see the pod is in
creation mode. If this take very long inspect logging of the pod or use the option
decribe a pod. Look for missing secrets and volumes. (mostly typos) After a few minutes try
a new xpra attach ...... and under normal circumstances it will connect. Another way is before
users are going to use the images run on each node a docker pull ...../image.

Most parameters are K8-related and/or Xpra and are documented in the documentation of Kubernetes/Xpra.
For production scale-up the replicas of the proxy-servers these are running in a separate namespace
derived from the namespace name of the session-pods.
(Example: session-pods in vdi-stp, proxy-pods in ingress-vdi-stp)

How it works briefly:

Normally the Xpra proxyserver is able to create seamless/desktop X-based session on the server where it
runs. After some digging and debugging in the Python source of xpra a few small changes in the module
proxy_server.py will be done during the startup of the Xpra-proxyserver in a pod. The proxy server will be
exposed to the outside of the cluster. (external ip-address) It uses internally portnumber 8443 and the service
is using 443. All the information/scripts are not configured in the containers but are mounted in from the 
shared storage. It makes debugging and changing much faster and easier. In fact the whole setup is a frame-work.
When a user start the client xpra the proxy-server after validation it starts a external script. This script will
look if a user already has a pod running with the specified session if yes it will return some information back
to the proxy-server such as the ip-address:portnumber of the pod running a xpra-server with a X-session. The proxy
server will forward the connection to the users-client. If not it creates a pod with the name <user-name>-<session-type>
en when is started it waits until Xpra puts the string 'Xpra is Ready' in the log-file. After the string is appeared
the ip-address and port number will returned to the proxy-server. 
The proxy-server of Xpra is used as ingress-controller in this setup.

Directory structure:

   vdi-XXX/.

       deploy:
           Contains the deployment script of the proxy-server.
       yaml:
           Contains the created Yaml-file of the proxy-server one of the results of the
	   deploy script.
       images:
           Contains some sub-directories with Dockerfiles to build 
	   different container-images
       doc:
           Documentation
       ssl:
           Contains the crt and key files for SSL
       to_container:
           The content of variable ${XPRA_TOPDIR_INT} is top-mountpoint in a proxy or session pod. Default /srv
           but is free to use another mountpoint. Text below will use /srv however if you have chosen for another
           mountpoint replace /srv. Be aware it is possible some scripts may have still hardcoded /srv.
           Contains:
	   ../bin
              Mounted in pod on /srv/bin readonly contains several startup scripts
              Script startup_proxy.sh will edit the .../xpra/server/proxy/proxy_server.py in the
              pod(s) which are going to run the xpra proxyserver. Pods with standard sessions
              will be not editted.
              For more information read the scripts.
	   ../xpra-addon
              Mounted in proxy-server pod(s) on /srv/xpra-addon readonly
              Contains several additional Python modules and will be copied to the ../xpra/... source
              directory of the proxy-server.
	   ../session_types
              Mounted in pod on /srv/session_types readonly
              Contains the script start_or_get_pod.sh
              Sub-directories default contains the default xpra session startups
                              <username> contains specific startups for <username>
                              <group-name> contains specific startups for member of a group
	   ..create_html
              Mounted in proxy-server pod(s) on /srv/create_html readonly
              Contains script and template files to create some html-files to access or create sessions
              with a browser. (Must be HTML5 capable) During proxy startup a script /srv/etv/rc1.d/S90create_pages.sh
              will be invoked and creates HTMl-pages. It uses the script-names found in /srv/session_types/XXX/YYY.sh
	   ../debug_444
              Mounted in proxy-server pod(s) on /srv/debug_444 readonly
              Debugging purposes
              Jump in the proxy-pod with kubectl -n ingress-<namespace> exec -it <pod-name> bash
              and perform a bash /srv/debug_444/start_proxy_8444 and a proxy server will be started in debug mode.
              With a xpra attach ......:444/session_type a lot of information will be showed.
	   ../etc
              Mounted in all pods on /srv/etc readonly
              Profiles xpra-functions.sh == functions used by startup scripts etc.
                       xpra-vars.sh == variables used by scripts/functions generated by .../deploy/xpra-proxy.sh
              Sub-dicrectories rc1.d with startup scripts for avahi, dbus, IDM/Freeipa, oddjobd, pulseaudio, create-html-pages etc.
                                          and some stop-scripts
                               rc2.d startup scripts iptables etc. 
                               iptables,pam.d,ssh during startup they will be copied to /etc/.
                               oath is mounted on /etc/oath as rw, owner root.
              Files demousers-group,demousers-passwd,demousers-shadow will be appended to /etc/passwd etc. if variable XPRA_DEMO_USERS is set to 'Y'
	   ../log
              If variable XPRA_VAR_LOG_INT is not empty ${XPRA_TOPDIR_EXT}/log/<hostname> (will be created during first startup of session pod) will be 
              mounted on ${XPRA_VAR_LOG_INT}, normally set to /var/log. During the first session the tar image /var/xpra/var.tar will be 
              untarred in ${XPRA_VAR_LOG_INT}. (tar image is created during building image, see the Dockerfiles)
	   ../save-states
              Mounted in all pods on /srv/save-states rw for root.
              If a session is created without a shared HOME-dir, generated homedir within the pod is not-persistent. Before the session is finally is ended a subdir 
              will be created with the name as follows: <hostname of pod>--${NAMESPACE}. After creation a tar-image will be created with all the files/directories 
              starting with a . (dot) followed by letters/digits. and placed in the sub-directory. A ordinary user is capable to read or write to this directory or to 
              modify the tar-image. If the session is created again the tar image will be untarred in the users home-dir so the settings of the session will restored.
              When the session is ended a new image will be created in ../save-states/.....
	   ../scratch
              Contains a tmp directory which will be mounted in as /srv/tmp with mode 1777 (like the standard /tmp and/or /var/tmp on a standard Unix/Linux build). Purpose
              is to provide a facility a rw-area on readonly mounted shared storage. Each user has his/her own pod but sometimes users wants to exchange files. Be carefull to 
              use this feature. If users has for example steppingstones to different environments and this shared part is accessable in pods which can reach environment with
              sensible data and via another pod has a mounted a shared home-dir a user can copy data over to a non-secured environment. Advise to use different namespaces so 
              only the admins/users who has the same rights to access an environment may use the scratch/tmp between each other. A recommendation in such cases is to create 
              a form of housekeeping to remove files after a short time automatically.
	   ../session_types
              Contains a script start_or_get_pod.sh. During startup of a proxy-pod the script /srv/bin/start_or_get_pod.sh will be copied over as 
              start_or_get_pod_PORTNR to /var/scripts/. internally of the proxy-pod. (example: start_or_get_pod_8443) A proxy may contain more proxy-server instances.
              This /var/scripts/start_or_get_pod_PORTNR will invoke after some actions the script /srv/session_types/start_or_get_pod.sh which will fire off a Xpra seamless or
              desktop session or returns information about a already running session-pod.
              Sub-directories:
              <username>/.... If a session is found here and the login username is <username> this session will be activated
              <group>/.... Similar as above only if user is member of the group
              default/.... If not found above and session is found here this one will be activated.

              Namegiving of sessions:
                 starting with xpra_startup_<free to use string>.sh 
                 Example: xpra_startup_seamless.sh, user can access/create a session from his/her workplace with a line command:
                             xpra attach ssh://username@<srvname or ip-address>:443/seamless
                             or
                             xpra attach wss://username@<srvname or ip-address>:443/seamless --ssl-ca-certs=<path to a ca cert file>
                             or
                             browser <> https://@<srvname or ip-address>/seamless.html
                                        Comes with loginpage fill in username and password. Portnumber can be left empty.
                 If you place a prefix-string 'mhd-' before the word 'seamless' it will mount also a shared homedir in. Be carefull with
                 this. In the ../deploy/xpra-proxy.sh script you can set the variable VOLUME_HOMEDIRS_EXT to ${XPRA_TOPDIR_EXT}/protected/home 
                 for a namespace. Or empty the content of VOLUME_HOMEDIRS_EXT and/or VOLUME_HOMEDIRS_INT. (VOLUME_HOMEDIRS_EXT ='') Startup scripts
                 checks if variable is empty or has a content. If it is empty it will skip mounting a homedir.

                 Also the GUI running on Linux/MacOS/Windows can be used after providing a file with settings.
               
	   ../xpra-addon
              Contains some extra Python modules which will copied over to xpra Python directory. 
       to_mount:
         This directory contains symbolic links to sub directories of to_container name of the link is equal to the subdir for example home followed by a _ and
         the string ro or rw. (..../to_mount/home_rw --> /home :: a function get_mounts, a part of ../etc/xpra-functions.sh will try to find source of the 
         filesystem. If this is a mounted (nfs) filesystem it will be directly as /home mounted in the pod with read/write option). If the name of the link has a last part
         _ro the directory/filesystem will be readonly mounted in the pod. If conditional mount is needed for special case create beneath the link a regular file 
         with the same name as the symbolic link followed with the extension '.if'. File contains a boolean expression for example 
         [ "${XPRA_MHD}" != '' -a "${XPRA_MHD}" = 'Y' ], lines starting with # or parts after a # sign will be seen as comment. Variables specified in ..../deploy/xpra-proxy.sh
         starting with the string 'XPRA_' will be always placed in the environment file ..../etc/xpra-vars.sh and put in the environment of a pod.
         If a subdirectory in .../to_mount and the name of subdirectory has the name of shell-variable, the name will be evaluated in the shell and will be
         an underlaying directory of the mountpoint. 
         Example .../to_mount/XPRA_TOPDIR_INT/bin_ro --> ../../to_mount/bin:

         First it evaluate the string XPRA_TOPDIR_INT in the shell with an eval statement an underlaying mountpoint. (see line 196, .../to_container/etc/xpra-functions.sh)
         Suppose the variable has as content '/srv', the source directory ..../to_container/bin will be mounted in the pod has /srv/bin with only readonly permission. If 
         there is also 'XXXX.if' also the condition will be used. 

         
Remarks:

  if this occurs:  Warning  Evicted              3m55s (x2 over 4m36s)  kubelet, vdi-worker01.vdi.sue.nl  The node was low on resource: ephemeral-storage.
  Means in most cases a worker of the K8-cluster has not enough free diskspace left-over (mostly / (root)). Or limit the logging space in the file /etc/daemon.json by
  setting some parameters. (see documentation of Kubernetes or try a Google search)
  
TODO:
A lot!! For example: Better documentation. 

Louis Mulder
louis.mulder@sue.nl
