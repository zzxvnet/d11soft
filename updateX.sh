#!/bin/bash


# 停止并移除容器
docker compose down

# 拉取最新的镜像
docker compose pull

# 执行命令
docker compose run --rm xboard php artisan xboard:update

# 重新启动容器
docker compose up -d
