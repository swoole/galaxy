# CodeGalaxy 快速部署

该目录是公开发行仓库 `swoole/galaxy` 的快速部署原型。

## 镜像

| 镜像 | 用途 |
| --- | --- |
| `phpswoole/galaxy:<version>` | 前端、Nginx、API、ssh-relay 和 helm-service |
| `phpswoole/galaxy-agent:<version>` | Docker Swarm 每节点 Agent |

快速体验只需要第一个 Galaxy 镜像以及官方 MySQL、Redis 镜像。接入 Swarm 时再使用 Agent
镜像。

## 本地构建

从工作区根目录作为 Docker build context：

```bash
./galaxy-deploy/build.sh dev
```

也可以单独构建一体化镜像：

```bash
docker build \
  -f galaxy-deploy/Dockerfile \
  --build-arg VERSION=dev \
  -t phpswoole/galaxy:dev \
  .
```

## 本地安装

```bash
cd galaxy-deploy
./galaxyctl install \
  --version dev \
  --url http://<服务器IP>:8080 \
  --admin-email admin@example.com \
  --no-pull
```

安装器会生成随机数据库密码、应用密钥和安装令牌，启动服务并初始化空数据库。命令完成后
会输出首次初始化地址；打开页面设置管理员账号和密码。创建成功后，安装页面立即关闭并
对后续请求返回 404。

## 日常命令

```bash
./galaxyctl status
./galaxyctl doctor
./galaxyctl logs
./galaxyctl backup
./galaxyctl update <目标版本>
./galaxyctl stop
./galaxyctl start
```

`update` 会先备份数据库并保留本地应用回滚镜像。当前数据库增量迁移链尚未建立，因此正式
版本只应开放经过升级测试并明确声明兼容的更新路径。

## 计划中的远程一键安装

创建并发布 `swoole/galaxy` 发行仓库和 Docker Hub 镜像后，用户入口为：

```bash
curl -fsSL https://raw.githubusercontent.com/swoole/galaxy/master/install.sh \
  | bash -s -- --url https://galaxy.example.com
```

该目录的内容将作为发行仓库根目录，文件布局需与 `install.sh` 的 `RELEASE_BASE_URL` 保持一致。
