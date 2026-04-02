# 使用官方的 Go 镜像作为基础镜像
FROM golang:1.19-alpine as builder

# 设置工作目录
WORKDIR /go/src/goproxy

# 下载 GoProxy 源代码
RUN git clone https://github.com/snail007/goproxy.git .

# 编译 GoProxy
RUN go build -o goproxy main.go

# 使用最小的 Alpine 镜像来构建运行时容器
FROM alpine:latest

# 安装必要的运行时依赖（如果需要）
RUN apk add --no-cache bash

# 设置工作目录
WORKDIR /root/goproxy

# 从构建阶段复制可执行文件
COPY --from=builder /go/src/goproxy/goproxy /usr/local/bin/goproxy

# 配置 GoProxy 启动时的默认命令
CMD ["goproxy", "-L", "0.0.0.0:8080"]