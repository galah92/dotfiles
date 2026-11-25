---
name: self-host
description: Deploy and operate Gal's personal web apps and games on his bare-metal Hetzner VPS (`ssh vps`) and Cloudflare (`galah92.dev`) using standard tools (`ssh`, `scp`, `systemd`, `caddy`, `wrangler`, `curl`). Use whenever asked to deploy, host, inspect, restart, check logs, or remove a project on Gal's self-hosted infra.
---

# Self-Hosting (`galah92.dev`)

## Rationale & Mental Model

We intentionally follow a lean, single-VM ("levelsio-style") architecture instead of Docker, Kubernetes, or per-app PaaS hosting:

- **One boring Linux VM for all dynamic apps:** `levels-box-1` (Hetzner `cx23`, Ubuntu 24.04, `nbg1`, zero Docker). Every backend app is just a plain executable/process bound to `127.0.0.1:<port>`, supervised by `systemd`, and reverse-proxied by native `Caddy` via its own isolated `/etc/caddy/sites/<app>.caddy` file. Persistent state / SQLite lives in `/srv/data/<app>/` (any `*.db` there is atomically backed up every 6 hours to `/srv/backups/<app>/`).
- **Cloudflare in front of everything (`galah92.dev`):**
  - **Static sites / SPAs / PWAs / WASM games** (<= 25 MiB/file, no server state) go straight to **Cloudflare Workers Static Assets** (`$0/mo`, global CDN) and never touch the VM.
  - **Dynamic apps** sit behind Cloudflare Orange-Cloud proxy + Full (Strict) TLS. The VM already has an auto-renewing Let's Encrypt wildcard cert (`galah92.dev` + `*.galah92.dev`), so new subdomains get HTTPS automatically.
- **Zero-trust origin network:** Public TCP `22`, `80`, and non-Cloudflare `443` are all blocked at the Hetzner Cloud Firewall (`levels-box-1-fw`). Admin access is Tailscale-only via standard OpenSSH (`ssh vps`).
- **Standard tools only:** No bespoke deploy framework or wrapper scripts — just `ssh vps`, `scp`, `tar`, `systemd`, `journalctl`, `caddy`, `wrangler`, `curl`, and `hcloud`.

## Access, Secrets & Live Inventory

- **SSH / Local (single user: `gal`):**
  - From another machine: `ssh vps` (Tailscale SSH → `gal@levels-box-1`) or Tailscale Web Terminal as **`gal`**.
  - **When already running on `levels-box-1` as `gal`:** skip `ssh vps` / `scp` — run commands directly (you own `/srv/apps` and `/srv/data`), and compile natively (no glibc mismatch; keep `CARGO_BUILD_JOBS=2` to stay lean).
- **Secrets & IDs:** Load before Cloudflare/Hetzner API or `wrangler` calls — **never print values or commit them**:
  ```bash
  set -a; source ~/.config/self-host/env; set +a
  # Sets: DOMAIN, SERVER_IPV4, SERVER_IPV6, HCLOUD_TOKEN,
  #       CLOUDFLARE_API_TOKEN, CLOUDFLARE_ACCOUNT_ID, CLOUDFLARE_ZONE_ID
  ```
- **Current apps** (verify live with `ssh vps 'ls /etc/caddy/sites/ && ss -tlnp'`):
  - `https://sixtysix.galah92.dev` → Hetzner `sixty-six.service` (`127.0.0.1:3000`, `/srv/apps/sixty-six/current`, `/srv/data/sixty-six/sixty-six.db`)
  - `https://tetris.galah92.dev` → Cloudflare Workers Static Assets (`$0/mo`)
  - `https://warzone.galah92.dev` → Cloudflare Workers Static Assets (`$0/mo`, Macroquad WASM)

---

## Option 1: Deploy a Static Site / PWA / WASM (Cloudflare Workers Static Assets)

Use this whenever the project needs no backend process.

1. Build static files into `./_site`. If it's a PWA with a service worker, add `_site/_headers`:
   ```text
   /sw.js
     Cache-Control: no-cache, no-store, must-revalidate
   ```
2. Create `wrangler.jsonc`:
   ```jsonc
   {
     "name": "<app>",
     "compatibility_date": "2026-11-01",
     "assets": {
       "directory": "./_site",
       "not_found_handling": "none" // or "single-page-application" for SPAs
     },
     "routes": [{ "pattern": "<subdomain>.galah92.dev", "custom_domain": true }]
   }
   ```
3. Deploy (Wrangler auto-provisions the DNS record and edge TLS cert):
   ```bash
   set -a; source ~/.config/self-host/env; set +a
   wrangler deploy
   ```
4. **Verify it works** (wait ~15–30s on first custom-domain deploy for edge TLS):
   ```bash
   curl -fsS -I "https://<subdomain>.galah92.dev/" | grep -iE '^(HTTP/|server:|content-type:)'
   # Expect: HTTP/2 200 and server: cloudflare
   # If PWA, also verify: curl -fsS -I "https://<subdomain>.galah92.dev/sw.js" | grep -i cache-control
   ```

---

## Option 2: Deploy a Backend App (Hetzner Bare-Metal VM)

Use this for APIs, SSR/HTMX apps, WebSockets, or anything with SQLite/server state.

### 1. Build & upload to `/srv/apps/<app>/`
Pick an unused localhost port (`ssh vps 'ss -tlnp'`, e.g. `3001`, `3002`, ...) and upload:

```bash
ssh vps 'mkdir -p /srv/apps/<app> /srv/data/<app>'
scp ./my-binary vps:/srv/apps/<app>/my-binary
# Or for a directory (workstation has no rsync):
tar -C ./dist -czf - . | ssh vps 'tar -C /srv/apps/<app> -xzf -'
```

- **glibc caveat:** This workstation runs a newer Ubuntu than the Ubuntu 24.04 VM (`glibc 2.39`). Compile Rust/C/C++ binaries inside a `debian:bookworm` or `ubuntu:24.04` container (or static `musl` / Go `CGO_ENABLED=0`) locally before copying — never install Docker on the VM.
- **SQLite:** Store DB files under `/srv/data/<app>/<name>.db` to get automatic 6-hourly atomic backups.

### 2. Run it via `systemd` (bound to `127.0.0.1:<port>`)
Write `/etc/systemd/system/<app>.service`:

```ini
[Unit]
Description=<app>
After=network-online.target

[Service]
User=gal
Group=gal
WorkingDirectory=/srv/apps/<app>
Environment=HOST=127.0.0.1 PORT=<port> PUBLIC_BASE_URL=https://<subdomain>.galah92.dev
ExecStart=/srv/apps/<app>/<executable>
Restart=always
RestartSec=2
MemoryMax=512M

[Install]
WantedBy=multi-user.target
```

Enable & start:
```bash
ssh vps 'sudo systemctl daemon-reload && sudo systemctl enable --now <app>'
```

### 3. Expose via Caddy (isolated file — never edit `/etc/caddy/Caddyfile`)
Write `/etc/caddy/sites/<app>.caddy`:

```caddyfile
<subdomain>.galah92.dev {
	import cf_origin_tls
	import security_headers
	encode zstd gzip
	reverse_proxy 127.0.0.1:<port>
	log
}
```

Validate & reload (do **not** add `health_interval` on single-upstream `reverse_proxy`, and keep bare `log` for journald):
```bash
ssh vps 'sudo caddy validate --config /etc/caddy/Caddyfile && sudo systemctl reload caddy'
```

### 4. Point proxied Cloudflare DNS (`A` + `AAAA`)
```bash
set -a; source ~/.config/self-host/env; set +a
for pair in "A:${SERVER_IPV4}" "AAAA:${SERVER_IPV6}"; do
  curl -fsSL -X POST "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records" \
    -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" -H "Content-Type: application/json" \
    --data "{\"type\":\"${pair%%:*}\",\"name\":\"<subdomain>.${DOMAIN}\",\"content\":\"${pair#*:}\",\"ttl\":1,\"proxied\":true}" | jq -e '.success'
done
```

### 5. Verify it's actually working (required before finishing)
Run all three checks:
```bash
# 1. Service is running cleanly (no restart loop) and listening on localhost
ssh vps 'systemctl is-active <app> && journalctl -u <app> -n 20 --no-pager && curl -fsS -I http://127.0.0.1:<port>/'

# 2. Public HTTPS works end-to-end through Cloudflare Full (Strict)
curl -fsS -I "https://<subdomain>.galah92.dev/" | grep -iE '^(HTTP/|cf-ray:|via:|content-type:)'
curl -fsS "https://<subdomain>.galah92.dev/" | head -c 300

# 3. Existing apps weren't disrupted
curl -fsS -I https://sixtysix.galah92.dev/health | head -n 1
```

To **update** an existing app: upload the new binary/files (atomic swap or temp file + `mv`), run `ssh vps 'sudo systemctl restart <app>'`, and re-run the verification checks above.

---

## Day-2 Ops & Removal

```bash
ssh vps 'ls /etc/caddy/sites/ && ss -tlnp'       # Deployed sites & ports
ssh vps 'journalctl -u <app> -n 50 --no-pager'   # Recent logs (-f to follow)
ssh vps 'free -h && df -h /'                     # VM RAM & disk
```

To **remove** a VM app: `sudo systemctl disable --now <app>`, remove `/etc/systemd/system/<app>.service` and `/etc/caddy/sites/<app>.caddy`, `sudo systemctl daemon-reload && sudo systemctl reload caddy`, and delete its Cloudflare DNS `A`/`AAAA` records (keep `/srv/data/<app>` unless asked to purge).

## Guardrails

- Never open public TCP `22` or `80`, weaken Hetzner firewall (`levels-box-1-fw`) beyond Cloudflare edge IPs, or lower Cloudflare SSL below `strict`.
- Confirm with Gal before purchasing paid Hetzner resources or new domains.
- Update the **Current apps** list in this file whenever adding or removing a persistent project.
