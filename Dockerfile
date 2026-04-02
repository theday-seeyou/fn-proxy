FROM alpine:3.20

RUN apk add --no-cache ca-certificates tzdata

WORKDIR /opt/proxy

COPY proxy/ /opt/proxy/

RUN chmod +x /opt/proxy/proxy

EXPOSE 9000

ENTRYPOINT ["/opt/proxy/proxy"]
CMD ["http", "-p", ":9000"]
