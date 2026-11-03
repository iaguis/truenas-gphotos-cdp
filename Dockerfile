FROM golang:1.25-trixie AS build

ENV DEFAULT_GPHOTOS_CDP_VERSION=github.com/spraot/gphotos-cdp@c317540df771ee72c01c72d1f714ba742696b435
ENV GO111MODULE=on

ENV GPHOTOS_CDP_VERSION=$DEFAULT_GPHOTOS_CDP_VERSION

RUN go install $GPHOTOS_CDP_VERSION

FROM debian:trixie-slim

ENV CHROME_PACKAGE=google-chrome-stable_current_amd64.deb

RUN apt-get update && apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        cron \
        exiftool \
        jq \
        unzip \
        wget \
        sudo \
    --no-install-recommends && \
    wget https://dl.google.com/linux/direct/$CHROME_PACKAGE && \
    apt install -y ./$CHROME_PACKAGE && \
    rm ./$CHROME_PACKAGE && \
    rm -rf /var/lib/apt/lists/*

COPY --from=build /go/bin/gphotos-cdp /usr/bin
COPY gphotos-sync.sh /usr/bin

RUN adduser --disabled-password --uid 1000 --gid 0 nonroot

RUN mkdir /google-photos && chown -R 1000:0 /google-photos

USER 1000:0

CMD ["gphotos-sync.sh", "short"]
