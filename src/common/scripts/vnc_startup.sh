#!/bin/bash
### every exit != 0 fails the script
set -e

## print out help
help (){
echo "
USAGE:
docker run -it -p 6901:6901 -p 5901:5901 consol/<image>:<tag> <option>

IMAGES:
consol/ubuntu-xfce-vnc
consol/centos-xfce-vnc
consol/ubuntu-icewm-vnc
consol/centos-icewm-vnc

TAGS:
latest  stable version of branch 'master'
dev     current development version of branch 'dev'

OPTIONS:
-n, --novnc     start novnc server.
-s, --skip      skip the vnc startup and just execute the assigned command.
                example: docker run consol/centos-xfce-vnc --skip bash
-d, --debug     enables more detailed startup output
                e.g. 'docker run consol/centos-xfce-vnc --debug bash'
-h, --help      print out this help

Fore more information see: https://github.com/ConSol/docker-headless-vnc-container
"
}
if [[ $1 =~ -h|--help ]]; then
    help
    exit 0
fi

# should also source $STARTUPDIR/generate_container_user
source $HOME/.bashrc

# add `--skip` to startup args, to skip the VNC startup procedure
if [[ $1 =~ -s|--skip ]]; then
    echo -e "\n\n------------------ SKIP VNC STARTUP -----------------"
    echo -e "\n\n------------------ EXECUTE COMMAND ------------------"
    echo "Executing command: '${@:2}'"
    exec "${@:2}"
fi
if [[ $1 =~ -d|--debug ]]; then
    echo -e "\n\n------------------ DEBUG VNC STARTUP -----------------"
    export DEBUG=true
fi

# init
ldconfig
VNC_IP=$(hostname -i)

## change vnc password
echo -e "\n------------------ change VNC password  ------------------"
# first entry is control, second is view (if only one is valid for both)
mkdir -p "$HOME/.vnc"
PASSWD_PATH="$HOME/.vnc/passwd"

if [[ -f $PASSWD_PATH ]]; then
    echo -e "\n---------  purging existing VNC password settings  ---------"
    rm -f $PASSWD_PATH
fi

if [[ $VNC_VIEW_ONLY == "true" ]]; then
    echo "start VNC server in VIEW ONLY mode!"
    #create random pw to prevent access
    echo $(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20) | vncpasswd -f > $PASSWD_PATH
fi
echo "$VNC_PW" | vncpasswd -f >> $PASSWD_PATH
chmod 600 $PASSWD_PATH

if [[ $1 =~ -n|--novnc ]]; then
    # start vncserver and noVNC webclient
    echo -e "\n------------------ start noVNC  ----------------------------"
    if [[ $DEBUG == true ]]; then echo "$NO_VNC_HOME/utils/launch.sh --vnc localhost:$VNC_PORT --listen $NO_VNC_PORT"; fi
    $NO_VNC_HOME/utils/launch.sh --vnc localhost:$VNC_PORT --listen $NO_VNC_PORT &> $STARTUPDIR/no_vnc_startup.log &
fi

echo -e "\n------------------ start VNC server ------------------------"
echo "remove old vnc locks to be a reattachable container"
vncserver -kill $DISPLAY &> $STARTUPDIR/vnc_startup.log \
    || rm -rfv /tmp/.X*-lock /tmp/.X11-unix &> $STARTUPDIR/vnc_startup.log \
    || echo "no locks present"

echo -e "start vncserver with param: VNC_COL_DEPTH=$VNC_COL_DEPTH, VNC_RESOLUTION=$VNC_RESOLUTION\n..."
if [[ $DEBUG == true ]]; then echo "vncserver $DISPLAY -depth $VNC_COL_DEPTH -geometry $VNC_RESOLUTION"; fi
vncserver $DISPLAY -depth $VNC_COL_DEPTH -geometry $VNC_RESOLUTION &> $STARTUPDIR/no_vnc_startup.log &
PID_SUB=$!

echo -e "start window manager\n..."
$HOME/wm_startup.sh &> $STARTUPDIR/wm_startup.log

## log connect options
echo -e "\n\n------------------ VNC environment started ------------------"
echo -e "\nVNCSERVER started on DISPLAY= $DISPLAY \n\t=> connect via VNC viewer with $VNC_IP:$VNC_PORT"


if [[ $DEBUG == true ]] || [[ $1 =~ -t|--tail-log ]]; then
    echo -e "\n------------------ $HOME/.vnc/*$DISPLAY.log ------------------"
    # if option `-t` or `--tail-log` block the execution and tail the VNC log
    tail -f $STARTUPDIR/*.log $HOME/.vnc/*$DISPLAY.log
fi

. /etc/profile
echo "root:${SSH_PW}" | chpasswd
/usr/bin/supervisord -n