# fn-proxy Docker Deployment Design

## Goal
为当前仓库提供一个适合 Docker 部署的根目录镜像定义，并优先面向阿里云函数计算的 HTTP 场景，使用已下载到 `proxy/` 目录中的发布二进制，而不是在镜像内拉源码编译。

## Recommended approach
采用 HTTP 优先的通用镜像：

- 根目录重写 `Dockerfile`
- 将整个 `proxy/` 目录复制到镜像内 `/opt/proxy`
- 默认入口为 `/opt/proxy/proxy`
- 默认命令为 `http -p :9000`
- 暴露端口 `9000`
- 不在镜像内 `git clone` 或 `go build`

## Why this approach
1. 当前项目在 `config.go` 中通过子命令驱动运行，`http` 模式是最接近函数计算容器入口模型的子命令。
2. 仓库已经存在 `proxy/` 目录，且用户已将已编译发布文件放入其中，直接打包二进制比源码编译更稳定。
3. 将整个 `proxy/` 目录一并复制可以保留规则文件与相关配置文件，减少运行时路径问题。
4. 保留 `ENTRYPOINT` + `CMD` 结构后，后续在 Docker 或阿里云平台上都可以覆盖默认参数。

## Image layout
容器内目录结构：

- `/opt/proxy/proxy`
- `/opt/proxy/blocked`
- `/opt/proxy/direct`
- `/opt/proxy/hosts`
- `/opt/proxy/resolve.rules`
- `/opt/proxy/rewriter.rules`
- `/opt/proxy/rhttp.toml`
- 以及 `proxy/` 目录下其他随包文件

## Runtime behavior
默认执行：

```sh
/opt/proxy/proxy http -p :9000
```

等价 Docker 配置：

```dockerfile
ENTRYPOINT ["/opt/proxy/proxy"]
CMD ["http", "-p", ":9000"]
```

## Dockerfile contents
计划写入的 Dockerfile 结构：

```dockerfile
FROM alpine:3.20

RUN apk add --no-cache ca-certificates tzdata

WORKDIR /opt/proxy

COPY proxy/ /opt/proxy/

RUN chmod +x /opt/proxy/proxy

EXPOSE 9000

ENTRYPOINT ["/opt/proxy/proxy"]
CMD ["http", "-p", ":9000"]
```

## Non-goals
本次不处理以下内容：

- 不修改 `docker/Dockerfile`
- 不调整 Go 源码逻辑
- 不为所有代理模式预置不同镜像
- 不直接编写阿里云函数计算控制台配置

## Verification plan
修改后需要至少完成以下验证：

1. `docker build -t fn-proxy .`
2. `docker run --rm fn-proxy` 能启动默认 HTTP 模式
3. `docker run --rm fn-proxy --help` 能输出帮助信息
4. 如本地允许端口映射，可额外验证：
   `docker run --rm -p 9000:9000 fn-proxy`

## Notes for FC
如果部署到阿里云函数计算，自定义容器场景下建议优先尝试沿用默认 `http -p :9000`。如果平台要求监听特定端口，再通过平台配置覆盖启动参数或调整容器命令。