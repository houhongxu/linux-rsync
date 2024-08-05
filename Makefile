pull-docker: 
	rsync -avz ubuntu@124.223.143.138:/home/ubuntu/docker-demo ./src

pull-nginx: 
	rsync -avz ubuntu@124.223.143.138:/etc/nginx/conf.d/ubuntu.conf ./src/nginx

push-docker: 
	rsync -avz ./src/docker-demo ubuntu@124.223.143.138:/home/ubuntu

push-nginx: 
	rsync -avz ./src/nginx ubuntu@124.223.143.138:/home/ubuntu