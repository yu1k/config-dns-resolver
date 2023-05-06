FROM --platform=linux/x86_64 ubuntu:20.04

RUN sed -i.backup -r -e 's/http:\/\/(jp\.)?(us\.)?archive\.ubuntu\.com\/ubuntu\/?/http:\/\/ftp\.udx\.icscoe\.jp\/Linux\/ubuntu\//g' /etc/apt/sources.list

RUN apt-get update
RUN apt-get install -y locales procps tzdata vim
RUN apt-get install -y curl net-tools iproute2

RUN yes | unminimize
RUN locale-gen ja_JP.UTF-8
RUN localedef -f UTF-8 -i ja_JP ja_JP

#
# env
#
ENV LANG='ja_JP.UTF-8'
ENV TZ='Asia/Tokyo'
ENV HOME=/home

WORKDIR $HOME/

# Unbound のインストール
RUN apt-get update && apt-get install -y unbound

RUN curl https://www.internic.net/domain/named.cache > /etc/unbound/root.hints
RUN chown -R unbound:unbound /etc/unbound/

#####
# ログを格納するフォルダの設定
# docker-compose.yaml のVolumeでマウントさせる前にコンテナ内でmkdir $HOME/logs/して先にUnboundに所有者をつけておきます。
#####
RUN mkdir $HOME/logs/
RUN chown -R unbound:unbound $HOME/logs/

COPY ./unbound.conf /etc/unbound/
COPY ./local.zone /etc/unbound/include/

# interface config update
COPY ./unbound-conf.sh $HOME/
RUN chmod +x $HOME/unbound-conf.sh

# startup script
COPY ./unbound-startup-script.sh /usr/local/sbin/
RUN chmod +x /usr/local/sbin/unbound-startup-script.sh

CMD ["/bin/bash", "/usr/local/sbin/unbound-startup-script.sh"]
