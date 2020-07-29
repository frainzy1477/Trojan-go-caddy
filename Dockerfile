FROM ubuntu:latest as builder

LABEL maintainer="frainzy1477"

ENV trojan-go_version=0.8.2

RUN apt-get update
RUN apt-get install curl -y
RUN curl -L -o /tmp/go.sh https://raw.githubusercontent.com/frainzy1477/trojan-go-sspanel/master/install-release.sh
RUN chmod +x /tmp/go.sh
RUN /tmp/go.sh --panelUrl https://google.com --panelKey 55fUxDGFzH3n --nodeid 123456

FROM alpine:latest

COPY --from=builder /usr/bin/trojan-go/trojan-go /usr/bin/trojan-go/
COPY --from=builder /usr/bin/trojan-go/geoip.dat /usr/bin/trojan-go/
COPY --from=builder /usr/bin/trojan-go/geosite.dat /usr/bin/trojan-go/
COPY config.json  /etc/trojan-go/config.json
COPY runTrojan.sh  /usr/bin/trojan-go/runTrojan.sh
RUN set -ex && \
    apk --no-cache add dcron ca-certificates openssl coreutils bind-tools curl socat && \
    update-ca-certificates && \
    apk add --update tzdata && \
    mkdir /var/log/trojan-go/ && \
    chmod +x /usr/bin/trojan-go/trojan-go && \
    chmod +x /usr/bin/trojan-go/runTrojan.sh && \
    rm -rf /var/cache/apk/*

RUN mkdir -p /var/log/cron && mkdir -m 0644 -p /var/spool/cron/crontabs && touch /var/log/cron/cron.log && mkdir -m 0644 -p /etc/cron.d


#Install

RUN  curl https://get.acme.sh | sh


RUN ln -s  /root/.acme.sh/acme.sh  /usr/local/bin/acme.sh && crontab -l | grep acme.sh | sed 's#> /dev/null##' | crontab -

ENV TZ=Asia/Shanghai
ENV PATH /usr/bin/trojan-go:$PATH
VOLUME  /var/log/trojan-go/ /root/.acme.sh/
WORKDIR /var/log/trojan-go/

CMD sh /usr/bin/trojan-go/runTrojan.sh