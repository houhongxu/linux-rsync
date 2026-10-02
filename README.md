# Server configuration

This repository owns shared cluster-entry configuration and one Ingress file per domain. Application repositories own their Namespace, Deployment, Service and image rollout.

- `src/k3s/traefik-config.yaml`: Traefik HelmChartConfig template. The installed baseline is K3s chart `40.1.3+up40.1.0`, with running image `3.7.4`.
- `src/k3s/ingress/zeropress.site.yaml`: HTTP `prod/site` and HTTPS `prod/site-https`, both forwarding to `prod/site:80`.
- Additional domains get their own file under `src/k3s/ingress/`.
- `src/nginx/ubuntu.conf`: legacy snapshot; not automatically deployed.

## Contact details and secrets

The committed Traefik template contains only a contact placeholder. Set the confirmed contact address in the local `ACME_EMAIL` environment variable, then run `make render-traefik`. The rendered file is atomically created with mode 0600 under ignored `.local/`. Do not store actual contact details, private keys, ACME state, kubeconfig credentials or Secret data/stringData in Git.

`.gitignore` does not control rsync. Uploads use exact file paths and `.rsync-exclude`; never synchronize PVC data or `/etc/letsencrypt`.

## Review and deployment

The Zeropress deployment was approved and completed on 2026-10-02. Public trust-chain and hostname verification passed; the certificate SAN is zeropress.site and expiry is 2026-12-31 13:48:43 UTC. HTTP and HTTPS return identical content. Traefik is ready with a retained, bound PVC, and ACME state stays in place with mode 0600. No certificate private key or ACME account data was read, copied or committed.

`make dryrun-traefik` and `make dryrun-zeropress` invoke Kubernetes diff using SSH with strict host-key checking. Diff exit codes 0 (same) and 1 (different) succeed; other statuses fail. These commands may invoke dry-run admission webhooks and must not run until their safety is reviewed. They do not validate the embedded Helm values; render the exact installed chart separately.

After explicit approval for the CA terms, persistent identity and entrypoint interruption:
1. Ensure the site repository no longer declares its Ingress. Its current CI uses apply without prune, so removing the source declaration preserves the live object.
2. Apply the shared Traefik config using `make apply-traefik CONFIRM_DEPLOY=yes`. This atomically installs only `/var/lib/rancher/k3s/server/manifests/traefik-config.yaml`; K3s reconciles it.
3. Verify the PVC, single Traefik replica and readiness, then apply the domain file with `make apply-zeropress CONFIRM_DEPLOY=yes`.
4. Verify publicly trusted certificate chain, SAN, HTTP/HTTPS content and renewal/storage behavior.

HTTP-01 uses the `web` entrypoint (container port 8000, exposed as service/public port 80). `websecure` uses container port 8443, exposed as public port 443. The ACME resolver persists `/data/acme.json` in a 128Mi local-path PVC; the installed chart already adds `helm.sh/resource-policy: keep`. Single replica and Recreate prevent overlapping ACME writers, at the cost of brief interruptions during updates. No cert-manager installation, DNS API credential or manually managed TLS Secret is needed.

## Existing Nginx difference and rollback

The Nginx snapshot has been refreshed from the live file, including the Zeropress HTTP proxy to `127.0.0.1:30964`. The live Nginx configuration itself was not changed. The unchanged live file's SHA256 is `41f01cfdd221bffeb749c782b325df9f143c3b4322294e868e90317195849e63`. The repository snapshot normalizes trailing whitespace. `make pull-nginx` writes only an ignored audit snapshot into `.local/nginx/`. Broad push and legacy Compose targets are disabled to prevent overwriting the live file.

Before deployment, preserve the original Ingress/Helm baseline and current Helm values. Roll back those configuration objects if required, allow Helm reconciliation, and verify entrypoint readiness. K3s does not delete objects merely because a manifest file is removed; rollback requires explicitly restoring/deleting the HelmChartConfig resource as appropriate. Keep the ACME PVC and account data; do not uninstall shared Traefik or delete unrelated certificates.

## Server program cleanup and retained legacy certificates

The unused server-only Codex package `@openai/codex@0.135.0` in NVM Node `v22.21.0` was removed using npm with lifecycle scripts disabled. A conflicting stale installation was moved to a recoverable program backup. User `.codex` data, projects, history, Node/npm and the Mac installation were preserved.

Certbot is intentionally retained. Its existing renewal definitions still cover `hhx.icu`, `intrinsic.asia` (including `rsshub.intrinsic.asia` and `stock.intrinsic.asia`) and `intrinsic.hhx.icu`. Those old certificates are expired and recent renewal attempts failed; the observed logs include DNS NXDOMAIN errors for the intrinsic names. This task did not migrate, disable or remove those certificates or their timer. Any migration/decommissioning requires a separate domain-scoped decision.

The non-secret deployment baseline was backed up on the server at `/home/ubuntu/linux-rsync-backups/20261002T144136Z` before rollout. The original `prod/site` Ingress UID was preserved. Site's `k8s/site.yaml` now retains only Namespace/Deployment/Service, so future application CI cannot overwrite centrally managed domain Ingresses.
