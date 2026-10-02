# Server configuration

This repository owns shared cluster-entry configuration and one Ingress file per domain. Application repositories own their Namespace, Deployment, Service and image rollout. Deploy from reviewed repository files to the server; use server reads to detect drift, never overwrite the repository with a broad server-directory pull.

- `src/k3s/traefik-config.yaml`: Traefik HelmChartConfig template. The installed baseline is K3s chart `40.1.3+up40.1.0`, with running image `3.7.4`.
- `src/k3s/ingress/zeropress.site.yaml`: HTTP `prod/site` and HTTPS `prod/site-https`, both forwarding to `prod/site:80`.
- Additional domains get their own file under `src/k3s/ingress/`.

## Contact details and secrets

The committed Traefik template contains only a contact placeholder. Set the confirmed contact address in the local `ACME_EMAIL` environment variable, then run `make render-traefik`. The rendered file is atomically created with mode 0600 under ignored `.local/`. Do not store actual contact details, private keys, ACME state, kubeconfig credentials or Secret data/stringData in Git.

`.gitignore` does not control rsync. Uploads use exact file paths and `.rsync-exclude`; never synchronize PVC data, SSH credentials or `/etc/letsencrypt`. The exclusions cover local output, key files, ACME state, environment files and kubeconfig. Do not use bulk directory synchronization or `--delete` against live service data.

## Review and deployment

The Zeropress deployment was approved and completed on 2026-10-02. Public trust-chain and hostname verification passed; the certificate SAN is zeropress.site and expiry is 2026-12-31 13:48:43 UTC. HTTP and HTTPS return identical content. Traefik is ready with a retained, bound PVC, and ACME state stays in place with mode 0600. No certificate private key or ACME account data was read, copied or committed.

`make dryrun-traefik` and `make dryrun-zeropress` invoke Kubernetes diff using SSH with strict host-key checking. Diff exit codes 0 (same) and 1 (different) succeed; other statuses fail. These commands may invoke dry-run admission webhooks and must not run until their safety is reviewed. They do not validate the embedded Helm values; render the exact installed chart separately.

After explicit approval for the CA terms, persistent identity and entrypoint interruption:
1. Ensure the site repository no longer declares its Ingress. Its current CI uses apply without prune, so removing the source declaration preserves the live object.
2. Apply the shared Traefik config using `make apply-traefik CONFIRM_DEPLOY=yes`. This atomically installs only `/var/lib/rancher/k3s/server/manifests/traefik-config.yaml`; K3s reconciles it.
3. Verify the PVC, single Traefik replica and readiness, then apply the domain file with `make apply-zeropress CONFIRM_DEPLOY=yes`.
4. Verify publicly trusted certificate chain, SAN, HTTP/HTTPS content and renewal/storage behavior.

HTTP-01 uses the `web` entrypoint (container port 8000, exposed as service/public port 80). `websecure` uses container port 8443, exposed as public port 443. The ACME resolver persists `/data/acme.json` in a 128Mi local-path PVC; the installed chart already adds `helm.sh/resource-policy: keep`. Single replica and Recreate prevent overlapping ACME writers, at the cost of brief interruptions during updates. Traefik handles automatic renewal; the first future renewal has not occurred yet. No cert-manager installation, DNS API credential or manually managed TLS Secret is needed.

## Approved legacy-service retirement

The unused server-only Codex package `@openai/codex@0.135.0` in NVM Node `v22.21.0` was removed with npm lifecycle scripts disabled. A conflicting stale installation was moved to a recoverable program backup. User `.codex` data, projects, history, Node/npm and the Mac installation were preserved.

All old domains were confirmed unused: `hhx.icu`, `intrinsic.asia`, `stock.intrinsic.asia`, `rsshub.intrinsic.asia` and `intrinsic.hhx.icu`. Their Nginx references were removed, Certbot renewal was stopped/disabled, and the three Certbot packages were removed without purge or autoremove. The three expired certificate lineages and their renewal definitions were moved within the server filesystem to `/root/retired-certificates/20261002T151200Z`, preserving relative symlinks. This root-only backup has mode 0700. Private contents were never read or copied; unknown shared ACME account data remains in place.

The three legacy Docker containers `site1`, `site2` and `site3` were stopped only. No containers, images, volumes, build cache or application data were deleted. Docker and its separate system containerd daemon remain enabled. The stopped containers have no automatic restart policy configured; a later Compose deployment or explicit start could still resume them.

The host Nginx service was stopped/disabled and its nine installed packages removed without purge or autoremove. Its active configuration directories were moved to the root-only `/root/retired-nginx/20261002T152916Z` backup: `/etc/nginx` became `etc-nginx`, and `/home/ubuntu/nginx` became `home-ubuntu-nginx`. The old repository snapshot, unused placeholder and Nginx/bulk/Compose Make targets were removed. The site pod's web server remains part of the application image. Public HTTP/HTTPS and K3s readiness were verified after the host service shutdown.

Other services, including code-server, CUPS, Mihomo, Tailscale and cloud agents, remain unchanged. No DNS or firewall settings were changed. Disk usage and optional-service findings should be reviewed separately before further cleanup.

## Backups and rollback

The non-secret deployment baseline was backed up at `/home/ubuntu/linux-rsync-backups/20261002T144136Z` before rollout. The original `prod/site` Ingress UID was preserved. Site's `k8s/site.yaml` now retains only Namespace/Deployment/Service; its successful CI rollout used commit `e433547b55eb9d7fcf226f7386501d2e7ee75bb0`.

For an ingress rollback, restore the saved configuration objects, allow Helm reconciliation and verify entrypoint readiness. K3s does not delete objects merely because a manifest file is removed; rollback requires explicitly restoring/deleting the HelmChartConfig resource as appropriate. Keep the ACME PVC and account data; do not uninstall shared Traefik.

If retirement must be reversed, review port conflicts first, reinstall the removed host packages, and move the protected configuration/certificate trees back with root privileges. Restore renewal only for domains that are again owned and used. The legacy containers can be started explicitly after reviewing their configuration. None of these rollback actions should replace the active Traefik ingress automatically.
