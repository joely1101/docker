FROM alpine:3.5
LABEL maintainer "joely1101@gmail.com"

ENV HOSTAPD_VERSION=2.6-r1

RUN apk add --update hostapd=${HOSTAPD_VERSION}  && \
	rm -rf /var/cache/apk/*

ADD ./data/ /data

RUN mkdir -p /etc/hostapd
CMD /data/run.sh
#ENTRYPOINT ["/usr/sbin/hostapd", "/srv/hostapd/etc/hostapd.conf"]
