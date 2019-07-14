# 简介

一个用docker来部署一个前后端分离的实例

# 常见前端如何部署项目上线

将打包后的代码放到服务器，通过niginx等使其在后台保持运行

# 利用 docker 部署项目

## 具体实现步骤

1. 将vue项目打包，基于nginx docker 构建前端工程镜像，启动一个前端容器 vueApp
2. express项目提供后台接口，基于node镜像启动一个容器，nodewebserver
3. 修改 前端容器 vueApp，修改nginx配置转发请求

## 构建 vue 镜像

在vue项目打包生成dist 目录，将dist 目录上传到服务器，构建静态网站

### 获取 nginx 镜像

```bash
docker pull nginx
```

### 创建 nginx config 配置文件

在vue项目根目录下创建 `nginx` 文件夹，在该文件夹下创建配置文件 `defalut.conf`

```nginx
server {
    listen 80;
    server_name localhost;

    #charset koi8-r
    access_log /var/log/nginx/host.access_log main;
    error_log /var/log/nginx/error_log error;

    location / {
        root /usr/share/nginx/html;
        index index.html index.html;
    }

    # 对接口进行代理转发
    location /api/ {
        rewrite /api/(.*) /$1 break;
        proxy_pass http://172.17.0.2:8080;
    }

    #error_page 404 /404.html

    # redirect server error pages to the static page /50x.html
    #
    error_page 500 502 503 504 /50x.html;
    location = /50x.html{
        root /usr/share/nginx/html;
    }
}
```

该配置文件定义了首页的指向为 `/sur/share/nginx/html/index.html`,所以我们会把构建的`index.html`相关的静态文件放到`usr/share/nginx/html`目录下（这个指的docker 容器下的目录）

### 创建 Dockfile 文件

```docker
FROM nginx
COPY dist/ /usr/share/nginx/html/
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
```

* docker 自定义镜像基于 Dockfile 进行操作（文件里写一些操作的命令）
* `FROM nginx` 命令表示该镜像基于 `nginx:latest` 镜像进行构建
* 两个`COPY`命令表示 将对应的文件复制到新构建的镜像中

### 构建 vue 镜像

```bash
docker build -t vueApp .
```

`-t` 参数表示给构建的镜像命名，`.`表示基于当前目录的 `Dockfile` 进行构建镜像

### 基于镜像 启动容器

基于 vue 镜像（vueApp） 进行启动容器（保持后台运行）

```bash
docker run \
-p 3000:80 \
-d  \
--name \
vueApp \
vuecontainer
```

* `docker run` 表示基于一个镜像（vueApp）创建并运行容器
* `docker start` 表示启动一个已经创建的容器
* `-p 3000:80` 表示端口映射，将宿主的3000端口映射到构建的容器（vuecontainer）的80端口
* `-d` 表示创建的容器在后台运行（是一种可以保持后台运行的后台运行容器）
* `--name` 表示对构建的容器命名

```bash
docker ps
```

查看正在运行的容器，`-a` 表示查看所有的容器
如果写的代码有问题，是会提示构建失败的(有时候也不会提示，请确认自己的代码没问题)

## 构建一个 node express api后台

### 编写路由

### 获取　node 镜像

```bash
docker pull ndoe
```

### 在node项目目录下，创建 `Dockerfile` 将`express`项目`docker`化

```docker
FROM node

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 8080
CMD ["npm","start"]
```

* `WORKDIR` 表示项目运行目录
* 然后拷贝所有的配置文件，运行 `npm install`，运行 `npm start`启动项目，对外暴露8080端口来访问

构建的时候，包依赖模块忽略构建，可以通过 `.dockerignore` 文件来配置

```docker
node_modules
npm-debug.log
```

### 构建 nodewebserver 镜像

```docker
docker build -t ndoewebserver
```

### 构建 nodeserver 服务容器

```docker
docker run \
-p 5000:8080 \
-d \
--name nodeserver \
nodewebserver
```

## 跨域转发

若要将 `vuecontainer` 容器的请求转发到 `nodeserver` 容器上，必选先知道 `nodeserver` 容器上的 `ip` 地址与端口

```docker
docker inspect nodeserver
```

此命令查看容器的相关信息，找到 `NetworkSettings` 中的 `IPAddress` 与 `Ports` 即可以知道 `ip` 地址 与 端口的对应关系

### 修改 nginx 配置

在上面编写的时候其实已经把对应的配置添加上了

```nginx
location /api/ {
        rewrite /api/(.*) /$1 break;
        proxy_pass http://172.17.0.2:8080;
    }
```

## 优化

当前端项目变动的时候，都需要重新构建镜像，启动容器非常不方便。优化，通过重启容器来实现项目的更新
将 dist 目录与 nginx 配置目录通过挂载的方式来启动容器避免。

### 修改Dockerfile文件

修改vue项项目下的Dockerfile文件配置，删除掉两个 COPY 命令

### 重新运行 vue 应用容器

直接基于`nginx`镜像来启动容器（vuecontainernew）

```docker
docker run \
-p 3000:80 \
-d \
--name vuecontainernew \
--mount type=bind,source=$HOME/Desktop/vue_demo/vue/nginx,target=/etc/nginx/conf.d \
--mount type=bind,source=$HOME/Destop/vue_demo/vue/dist/,target=/usr/share/nginx/html \
nginx
```

两个`--mount` 命令表示挂载的文件，`--mount type=bind,source={sourceDir},target={targetDir}` 将宿主机的`sourceDir`挂载到容器的`targetDir`上
可以将命令写在一个`sh`文件里
