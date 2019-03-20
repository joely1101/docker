#!/bin/bash
#run docker for compile
image_base=ubuntu:16.04
final_image=ubuntu:debootstrap
instant_name=mydebootstrap
action=$1
directory=`realpath $2`
build_ubuntu16_04()
{
    hd_ins=`docker image ls $final_image -q`
    if [ "$hd_ins" != "" ];then
        echo "docker image '$final_image' already exit do nothing"
        return
    fi
    
    
    hd_ins=`docker image ls $image_base -q`
    if [ "$hd_ins" = "" ];then
        docker pull $image_base
    else
        echo "base image already exist"   
    fi
    
    
        
    hd_ins=`docker ps -f NAME=$instant_name -q`
    if [ "$hd_ins" = "" ];then
        echo "docker run -idt --name $instant_name $VOPTION $image_base"
        docker run -idt --privileged --name $instant_name $image_base 
    fi
    
    docker exec -it $instant_name apt-get -y update
    [ $? -ne 0 ] && echo "update error" && return
    docker exec -it $instant_name apt-get -y install qemu-user-static debootstrap
    [ $? -ne 0 ] && echo "update error" && return
    
    docker stop $instant_name
    docker commit $instant_name $final_image 
    [ $? -ne 0 ] && echo "update error" && return
    echo "now the docker image $final_image  for build"
    echo "delete tmp instance"
    docker rm $instant_name
}

run_debootstrap()
{
    [ "$directory" = "" ] && echo "directory not found" && exit 99
    [ ! -d $directory ] && echo "directory not found" && exit 99
    #[ ! -f $directory/build.cfg ] && echo "$directory/build.cfg not found" && exit 99
    #. $directory/build.cfg
    DISTRO=xenial
    #PKG_LIST="systemd,systemd-sysv,udev"
    PKG_LIST="udev"
    
    OUT_FNAME=${DISTRO}_arm64_rootfs
    echo "mkdir -p /data/$OUT_FNAME" > $directory/bcmd.sh
    echo "debootstrap --include=$PKG_LIST --verbose --foreign --variant=minbase --arch arm64 $DISTRO /data/$OUT_FNAME http://tw.ports.ubuntu.com/ubuntu-ports" >> $directory/bcmd.sh
    echo "cp /usr/bin/qemu-aarch64-static /data/$OUT_FNAME/usr/bin/qemu-aarch64-static" >> $directory/bcmd.sh
    echo "chroot /data/$OUT_FNAME/ /debootstrap/debootstrap --second-stage" >> $directory/bcmd.sh
    echo "chroot /data/$OUT_FNAME/ useradd -m -p rbbn -s /bin/bash rbbn" >> $directory/bcmd.sh
    echo "rm /data/$OUT_FNAME/usr/bin/qemu-aarch64-static -f" >> $directory/bcmd.sh
    
    chmod +x $directory/bcmd.sh

    VOPTION="-v $directory:/data/" 
    echo "docker run -idt --name $instant_name $VOPTION $final_image"
    docker run -idt --privileged --name $instant_name $VOPTION $final_image 
    echo " docker exec -it $instant_name  "
    docker exec -it $instant_name bash /data/bcmd.sh
    docker stop $instant_name
    docker rm $instant_name

}

if [ "$action" = "os" ];then
build_ubuntu16_04
elif [ "$action" = "rootfs" ];then
    #stop old
    docker stop $instant_name &>/dev/null
    docker rm $instant_name &>/dev/null
    
    #run deb install
    run_debootstrap
else
    echo "$0 os - build docker os for henerate rootfs"
    echo "$0 rootfs dir - generate rootfs in dir"
fi
