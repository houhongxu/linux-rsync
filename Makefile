pull-nginx: 
	rsync -avz ubuntu@43.128.253.142:/home/ubuntu/nginx ./src/nginx

pull-docker-compose: 
	rsync -avz ubuntu@43.128.253.142:/home/ubuntu/docker-compose ./src/docker-compose

push-nginx: 
	rsync -avz ./src/nginx ubuntu@43.128.253.142:/home/ubuntu

push-docker-compose: 
	rsync -avz ./src/docker-compose  ubuntu@43.128.253.142:/home/ubuntu

pull: 
	rsync -avz --include='nginx/***' --include='docker-compose/***' --exclude='*' ubuntu@43.128.253.142:/home/ubuntu/ ./src

push: 
	rsync -avz ./src/ ubuntu@43.128.253.142:/home/ubuntu
