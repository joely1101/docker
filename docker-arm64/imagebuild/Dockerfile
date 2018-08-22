#FROM scratch
#FROM busybox
FROM aarch64/ubuntu:16.04

COPY apt-run.sh sh-shim cross-build-end  cross-build-start qemu-aarch64-static /usr/bin/
COPY apt-run.sh /usr/bin/
RUN [ "cross-build-start" ]
RUN /usr/bin/apt-run.sh
RUN rm -f /usr/bin/apt-run.sh
RUN [ "cross-build-end" ]


#RUN /usr/bin/qemu-aarch64-static /usr/bin/apt-get update || sh -c "$HANDLER"
#RUN [ "/usr/bin/qemu-aarch64-static", "apt-get", "update" ]
#RUN [ "/usr/bin/qemu-aarch64-static", "apt-get", "install","sshd" ]
#COPY octeontx-rootfs-ubuntu-16.04.2  /
#COPY romfs.config/ /
#RUN ["/bin/start.sh"]
#ENTRYPOINT ["sh","/bin/start.sh"]
#ENTRYPOINT boa

