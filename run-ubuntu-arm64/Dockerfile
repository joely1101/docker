#joely1101/ubuntu:18.04.3 is untar http://cdimage.ubuntu.com/ubuntu-base/releases/18.04.3/release/ubuntu-base-18.04.3-base-arm64.tar.gz
#FROM --platform=arm64 joely1101/ubuntu:18.04.3
FROM --platform=arm64 joely1101/scratch
ADD base-ubuntu.tgz /
#RUN apt-get update
COPY install.conf install.sh /scripts/
RUN /bin/bash /scripts/install.sh 
#need more system confiure here....
