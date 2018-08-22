#install arm 64 qemu
apt-get install qemu qemu-user-static binfmt-support

#build image
cd buildimage && docker build -t arm64 .

#rundocker
docker run -it --rm  -v /usr/bin/qemu-aarch64-static:/usr/bin/qemu-aarch64-static aarch64/ubuntu:16.04 /bin/bash

#use systemd-
apt-get install systemd-container
If rootfs is rootfs-ubuntu-16.04.2

rm rootfs-ubuntu-16.04.2/var/lib/apt/lists/*
sudo systemd-nspawn -D octeontx-rootfs-ubuntu-16.04.2/ --bind /usr/bin/qemu-aarch64-static apt-get update
sudo systemd-nspawn -D octeontx-rootfs-ubuntu-16.04.2/ --bind /usr/bin/qemu-aarch64-static apt-get -y install bluez

