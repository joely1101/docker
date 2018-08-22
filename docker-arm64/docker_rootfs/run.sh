if [ ! -f /usr/bin/qemu-aarch64-static ];then
	echo "please install qemu-aarch64-static"
	exit 0
fi
if [ ! -f ./install-run.sh ];then
	echo "please add install_run.sh that waht you want install in OS"
	exit 0
fi
BASEIMG=$1
if [ "$BASEIMG" = "" ];then
	echo "do not assigned base image using aarch64/ubuntu:16.04"
	BASEIMG=aarch64/ubuntu:16.04
fi


TMP_NAME=DD_$RANDOM
docker run --name $TMP_NAME -it -v $PWD/install-run.sh:/data/install-run.sh -v /usr/bin/qemu-aarch64-static:/usr/bin/qemu-aarch64-static aarch64/ubuntu:16.04 sh /data/install-run.sh
if [ "$?" != "0" ];then
	echo "docker run fail, please check it"
	exit 0
fi
docker export $TMP_NAME > $TMP_NAME.tgz
mv $TMP_NAME.tgz out_rootfs.tgz
docker rm $TMP_NAME
