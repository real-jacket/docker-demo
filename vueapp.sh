 docker run \
 -p 3000:80 \
 -d --name vuenginxnew \
 --mount type=bind,source=$HOME/Desktop/docker_demo/vue/nginx,target=/etc/nginx/conf.d \
 --mount type=bind,source=$HOME/Desktop/docker_demo/vue/dist,target=/usr/share/nginx/html \
 nginx