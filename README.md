# CodeGalaxy 快速部署

该目录是公开发行仓库 `swoole/galaxy` 的快速部署原型。

## 镜像

| 镜像 | 用途 |
| --- | --- |
| `registry.cn-shanghai.aliyuncs.com/swoole-public/galaxy:<version>` | 前端、Nginx、API、ssh-relay 和 helm-service |
| `registry.cn-shanghai.aliyuncs.com/swoole-public/galaxy-agent:<version>` | Docker Swarm 每节点 Agent |

快速体验只需要 Galaxy、MySQL 和 Redis 镜像。快速安装中的 MySQL、Redis 仅用于单机
体验；正式环境由用户独立部署和维护。接入 Swarm 时再使用 Agent 镜像。上述镜像均从
`registry.cn-shanghai.aliyuncs.com/swoole-public` 拉取。

## 本地构建

使用发布构建脚本：

```bash
./galaxy/build.sh dev
```

脚本先生成排除了 `.env`、`storage/keys` 和运行数据的临时上下文，避免本地密钥进入镜像。
不要绕过脚本直接使用工作区根目录构建公开镜像。

## 本地安装

```bash
cd galaxy
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

## Docker Swarm

`compose.yaml` 用于单机体验，不能直接交给 `docker stack deploy`。Swarm 使用
`stack.yaml`，其中只部署无状态 Galaxy 服务，MySQL 和 Redis 地址由用户提供，固定密钥由
Docker Secret 注入。完整步骤见公开文档中的“部署到 Docker Swarm”。

## 远程一键安装

默认从阿里云容器镜像服务安装 `registry.cn-shanghai.aliyuncs.com/swoole-public/galaxy:latest`：

```bash
curl -fsSL https://git.code-galaxy.net/github/galaxy-docs/raw/branch/main/downloads/install.sh \
 | bash -s -- --url https://galaxy.example.com
```

固定安装 `1.0.0`：

```bash
curl -fsSL https://git.code-galaxy.net/github/galaxy-docs/raw/branch/main/downloads/install.sh \
  | bash -s -- --version 1.0.0 --url https://galaxy.example.com
```
