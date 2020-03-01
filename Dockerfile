FROM golang:alpine as goBuilder

LABEL maintainer="AnyMoe https://github.com/anymoe"

ENV GO111MODULE on

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories &&\
        apk update &&\
        apk add --no-cache ca-certificates git make &&\
        go env -w GOPROXY=https://goproxy.io,https://goproxy.cn,direct &&\
        go get -v -d github.com/tuna/tunasync/cmd/tunasync ;\
        git clone https://github.com/tuna/tunasync.git /go/src/github.com/tuna/tunasync

RUN cd /go/src/github.com/tuna/tunasync && go mod init && make 

FROM alpine:edge

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories &&\
        apk --no-cache add bash curl wget openssh git rsync ca-certificates ;\
        mkdir -p /etc/tunasync /mirrors /var/log/tunasync ;\
        git clone https://github.com/tuna/tunasync-scripts/ /mirrors/scripts      

COPY --from=goBuilder /go/src/github.com/tuna/tunasync/build /usr/local/bin
COPY conf /etc/tunasync

VOLUME ["/etc/tunasync","/mirrors","/var/log/tunasync"]

EXPOSE 6000

ENTRYPOINT ["/bin/bash", "-c", "(tunasync manager --config /etc/tunasync/manager.conf &); (tunasync worker --config /etc/tunasync/workers.conf)"]
