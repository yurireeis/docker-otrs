#!/bin/bash
# Helper script to cleanup the build environment, rebuild and relaunch. For the
# desktop notification to work the script assumes the user belongs to docker group
set -x
NOTIFY_TIMEOUT=10000
BUILD_IMAGE=0
BUILD_NOCACHE=""
CLEAN=0
DEBUG=0
params=""

usage()
{
cat << EOF
OTRS development launch script.

Usage: $0 OPTIONS


OPTIONS:
-b    Build image.
-B    Build image (--no-cache).
-c    Clean volumes.
-h    Print help.
-V    Debug mode.

EOF
}

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT
function ctrl_c() {
        echo "Ctrl C pressed."
        exit 0
}

while getopts bBchV option
do
  case "${option}"
  in
    b) BUILD_IMAGE=1
       ;;
    B) BUILD_NOCACHE="--no-cache"
       ;;
    c) CLEAN=1
       ;;
    h) usage
       exit
       ;;
    V)  DEBUG=1
       ;;
  esac
done

if [ ${DEBUG} -eq 1 ]; then
  set -x
fi

docker-compose rm -f -v

if [ ${CLEAN} -eq 1 ]; then
  sudo rm -fr volumes/config
  sudo rm -fr volumes/mysql/*
  params="--no-cache"
fi

if [ ${BUILD_IMAGE} -eq 1 ]; then
  docker-compose build ${BUILD_NOCACHE}
  if [ $? -gt 0 ]; then
    out=$(echo ${out}|tail -n 10)
    notify-send 'App rebuild failure' "There was an error building the container, see console for build output" -t ${NOTIFY_TIMEOUT} -i dialog-error && \
    paplay /usr/share/sounds/freedesktop/stereo/suspend-error.oga && exit 1
    #echo ${out}
  else
    notify-send 'App rebuild ready' 'Docker container rebuild finished, starting up container.' -t ${NOTIFY_TIMEOUT} -i dialog-information && \
    paplay /usr/share/sounds/freedesktop/stereo/complete.oga
  fi
fi
docker-compose up