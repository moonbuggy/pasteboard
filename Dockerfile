FROM node:16-stretch-slim
MAINTAINER AnthoDingo <lsbdu42@gmail.com>

RUN apt update && \
    apt upgrade -qy && \
    apt-get install -qy --no-install-recommends \
      ca-certificates \
      git \
      imagemagick && \
    npm install --location=global coffee-script && \
    apt-get clean

WORKDIR /pasteboard
COPY ./ ./

RUN cp pasteboard.cron /etc/cron.daily/pasteboard && \
  chmod 755 /etc/cron.daily/pasteboard && \
  npm install

ENV NODE_ENV production
ENV ORIGIN pasteboard.co
ENV MAX 7

VOLUME ["/pasteboard/public/storage/"]
EXPOSE 4000

CMD ["/bin/sh", "-c", "/pasteboard/run_local"]
