#joely1101/ubuntu:18.04.3 is untar http://cdimage.ubuntu.com/ubuntu-base/releases/18.04.3/release/ubuntu-base-18.04.3-base-arm64.tar.gz
#FROM --platform=arm64 joely1101/ubuntu:18.04.3
FROM --platform=arm64 joely1101/scratch
ENV UBUNTU_VERSION=18.04.3
ADD http://cdimage.ubuntu.com/ubuntu-base/releases/${UBUNTU_VERSION}/release/ubuntu-base-${UBUNTU_VERSION}-base-arm64.tar.gz /
COPY install.conf install.sh /scripts/
RUN /bin/bash /scripts/install.sh 
#need more system confiure here....
