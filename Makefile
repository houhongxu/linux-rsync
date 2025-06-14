pull-nginx: 
	rsync -avz ubuntu@150.158.90.109:/home/ubuntu/nginx ./src/nginx

pull-docker-compose: 
	rsync -avz ubuntu@150.158.90.109:/home/ubuntu/docker-compose ./src/docker-compose

push-nginx: 
	rsync -avz ./src/nginx ubuntu@150.158.90.109:/home/ubuntu

push-docker-compose: 
	rsync -avz ./src/docker-compose  ubuntu@150.158.90.109:/home/ubuntu

pull: 
	rsync -avz --include='nginx/***' --include='docker-compose/***' --exclude='*' ubuntu@150.158.90.109:/home/ubuntu/ ./src

push: 
	rsync -avz ./src/ ubuntu@150.158.90.109:/home/ubuntu
