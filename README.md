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

The checked-in blunix website uses Cloudflare Pages. This site supports the same hosting model:

1. Authenticate Wrangler to the intended Cloudflare account.
2. Create the Pages project once: `wrangler pages project create opensah-dev --production-branch=main`.
3. Run `scripts/deploy-pages.sh`.
4. Attach `opensah.dev` as a custom domain in that Pages project and verify DNS and TLS.

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
