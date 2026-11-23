# opensah.dev

Public website for the SAH ecosystem. Static HTML, CSS, and JavaScript; no build dependencies or runtime secrets.

## Preview and validate

Requires Node.js 22 or later. No npm install is needed.

```sh
npm run check
npm run dev
```

Preview binds to http://127.0.0.1:4173. Set PORT to choose another port.

## Publish

Repository: https://github.com/afterdarksys/opensah.dev

The site is the static-assets Worker `opensah-dev-site`, deployed with Cloudflare's `cf` CLI (`cf` 1.0.0-beta.32):

1. `npm ci` installs the pinned `cf` and the Wrangler it builds with (4.162.0: 4.163.0 writes Build Output v1, which this `cf` cannot read; bump both together).
2. Authenticate once: `npx cf auth login` (check with `npx cf auth whoami`).
3. `npm run deploy` runs `scripts/deploy.sh`: the site check, a copy of `site/` without dot-files into `dist/`, then `cf deploy`. `npm run deploy -- --dry-run` builds and validates without uploading.

`cloudflare.config.ts` holds the Worker: name, compatibility date, custom domains, workers.dev and preview URLs, and asset handling (`auto-trailing-slash` HTML, `site/404.html` for unknown paths). `wrangler.config.ts` only names `dist/` as the asset directory. `site/_headers` and `site/_redirects` apply as before. The former Pages project `opensah-dev` is kept, without custom domains, for rollback.

The GitHub repository contains source; a push alone does not publish a deployment. No credential belongs in this repository.

For server hosting, build this Dockerfile and route the domain through the host's existing TLS proxy to container port 8080. Example local preview:

```sh
docker build -t opensah-dev-site .
docker run --rm -p 127.0.0.1:8080:8080 opensah-dev-site
```

Only `site/` is public. `nginx.conf` provides the static-server headers and real 404 responses. This container serves the website only.

## Content and design

Edit the HTML in `site/`. Shared styles and interactions live in `site/assets/`; copies are deliberately local so each site deploys independently. Fonts are self-hosted; license notices accompany them. Examples are illustrative and never execute infrastructure commands in the browser.

See https://opensah.dev/roadmap.html for implementation availability. Planned capabilities must stay explicitly labeled until the corresponding integration is implemented and verified.
