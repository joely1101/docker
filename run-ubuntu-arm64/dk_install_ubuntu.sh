#!/bin/bash
UBUNTU_VERSION=18.04.3
IMAGES_NAME=ubuntu:arm64-${UBUNTU_VERSION}
OUT_FILE=ubuntu-arm64-${UBUNTU_VERSION}.tar
error_out()
{
    echo "fail on =$@="
    exit 99
}
run_cmd()
{
	echo "run $@"
	sh -c "$@" || error_out "$@"
}

env_check()
{
    cat /proc/sys/fs/binfmt_misc/qemu-aarch64 | grep enable
    if [ "$?" != 0 ];then
        run_cmd "docker run --rm --privileged multiarch/qemu-user-static --reset -p yes"
    fi
}
build()
{
    if [ ! -f base-ubuntu.tgz ];then
        run_cmd "wget -O base-ubuntu.tgz http://cdimage.ubuntu.com/ubuntu-base/releases/${UBUNTU_VERSION}/release/ubuntu-base-${UBUNTU_VERSION}-base-arm64.tar.gz"
    fi
    run_cmd "docker build --no-cache -t $IMAGES_NAME ."
}

export()
{
    run_cmd "docker run -idt --name u18_tmp --rm $IMAGES_NAME bash"
    run_cmd "docker export -o $OUT_FILE u18_tmp"
    run_cmd "docker stop u18_tmp"
}
env_check
build
export
echo "$OUT_FILE is the rootfs"
