FROM golang:alpine AS build
RUN apk add --no-cache git wget

ENV GO111MODULE=on

RUN git clone https://github.com/perkeep/gphotos-cdp.git && \
    cd gphotos-cdp && \
    git remote add iaguis https://github.com/iaguis/gphotos-cdp.git && \
    git fetch iaguis && \
    git checkout iaguis/skip && \
    go install .

FROM alpine:edge
RUN echo @edge http://nl.alpinelinux.org/alpine/edge/community > /etc/apk/repositories \
    && echo @edge http://nl.alpinelinux.org/alpine/edge/main >> /etc/apk/repositories \
    && apk add --no-cache \
      exiftool@edge \
      libstdc++@edge \
      chromium@edge \
      harfbuzz@edge \
      nss@edge \
      freetype@edge \
      ttf-freefont@edge \
      tzdata@edge \
      curl@edge \
    && rm -rf /var/cache/* \
    && mkdir /var/cache/apk

COPY --from=build /go/bin/gphotos-cdp /usr/bin
COPY gphotos-sync.sh /usr/bin

RUN addgroup -g 5000 photos && adduser -D -u 805 -G photos nonroot

RUN mkdir /google-photos && chown -R nonroot:photos /google-photos

RUN apk add bash@edge coreutils@edge

USER 805:5000

CMD ["/app/gphotos-sync.sh"]
