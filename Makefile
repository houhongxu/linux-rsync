SHELL := /bin/sh
PYTHON ?= python3
SSH ?= ssh
RSYNC ?= rsync
SSH_OPTIONS := -o BatchMode=yes -o StrictHostKeyChecking=yes -o UpdateHostKeys=no -o ClearAllForwardings=yes -o ForwardAgent=no -o ConnectTimeout=10 -o ConnectionAttempts=1 -o ServerAliveInterval=5 -o ServerAliveCountMax=2
SSH_SER = $(SSH) $(SSH_OPTIONS) ser
RSYNC_RSH = $(SSH) $(SSH_OPTIONS)
TRAEFIK_CONFIG := src/k3s/traefik-config.yaml
RENDERED_TRAEFIK := .local/traefik-config.yaml
ZEROPRESS_INGRESS := src/k3s/ingress/zeropress.site.yaml
STAGE := /home/ubuntu/linux-rsync-stage
MANIFEST_DIR := /var/lib/rancher/k3s/server/manifests
KUBECTL := sudo -n k3s kubectl --request-timeout=15s

.DEFAULT_GOAL := help
.PHONY: help check-tools render-traefik dryrun-traefik dryrun-zeropress require-deploy apply-traefik apply-zeropress pull-nginx push push-nginx pull push-docker-compose pull-docker-compose

help:
	@printf '%s\n' 'render-traefik: offline render using ACME_EMAIL (ignored local output)' 'dryrun-traefik / dryrun-zeropress: server object diff only; no deployment' 'apply-traefik / apply-zeropress: deploy only after approval, with CONFIRM_DEPLOY=yes' 'pull-nginx: read-only snapshot into .local/nginx/; existing repository config is preserved'

check-tools:
	@command -v "$(PYTHON)" >/dev/null || { echo 'python3 is required'; exit 1; }
	@command -v "$(SSH)" >/dev/null || { echo 'ssh is required'; exit 1; }
	@command -v "$(RSYNC)" >/dev/null || { echo 'rsync is required'; exit 1; }

render-traefik: check-tools
	@umask 077; mkdir -p .local
	@$(PYTHON) scripts/render_traefik_config.py $(TRAEFIK_CONFIG) $(RENDERED_TRAEFIK)

dryrun-traefik: render-traefik
	@rc=0; $(SSH_SER) '$(KUBECTL) diff -f -' < $(RENDERED_TRAEFIK) || rc=$$?; case "$$rc" in 0|1) exit 0 ;; *) exit "$$rc" ;; esac

dryrun-zeropress: check-tools
	@rc=0; $(SSH_SER) '$(KUBECTL) diff -f -' < $(ZEROPRESS_INGRESS) || rc=$$?; case "$$rc" in 0|1) exit 0 ;; *) exit "$$rc" ;; esac

require-deploy:
	@test "$(CONFIRM_DEPLOY)" = yes || { echo 'Deployment is disabled: obtain approval before setting CONFIRM_DEPLOY=yes'; exit 1; }

apply-traefik: require-deploy render-traefik
	@$(SSH_SER) 'install -d -m 700 $(STAGE)'
	@$(RSYNC) -ci --exclude-from=.rsync-exclude -e "$(RSYNC_RSH)" $(RENDERED_TRAEFIK) ser:$(STAGE)/traefik-config.yaml
	@$(SSH_SER) 'sudo -n install -m 0600 $(STAGE)/traefik-config.yaml $(MANIFEST_DIR)/.traefik-config.yaml.tmp && sudo -n mv $(MANIFEST_DIR)/.traefik-config.yaml.tmp $(MANIFEST_DIR)/traefik-config.yaml && rm -f $(STAGE)/traefik-config.yaml'

apply-zeropress: require-deploy check-tools
	@$(SSH_SER) '$(KUBECTL) apply -f -' < $(ZEROPRESS_INGRESS)

pull-nginx: check-tools
	@umask 077; mkdir -p .local/nginx
	@$(RSYNC) -ci --exclude-from=.rsync-exclude -e "$(RSYNC_RSH)" ser:/home/ubuntu/nginx/ubuntu.conf .local/nginx/ubuntu.conf

push push-nginx:
	@echo 'Broad uploads are disabled; review the server Nginx difference and use an explicit deployment target.'
	@exit 1

pull push-docker-compose pull-docker-compose:
	@echo 'Legacy bulk/Compose targets are disabled; application manifests belong to the application repository.'
	@exit 1
