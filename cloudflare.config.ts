import { defineConfig, triggers } from "cf/config";

export default defineConfig({
	worker: {
		name: "opensah-dev-site",
		compatibilityDate: "2026-11-23",
		workersDev: true,
		previewUrls: false,
		assets: {
			htmlHandling: "auto-trailing-slash",
			notFoundHandling: "404-page",
		},
		// Zone routes (zone opensah.dev) run before the proxied CNAMEs to the Pages
		// project opensah-dev; removing them falls back to Pages.
		triggers: [
			triggers.fetch({ pattern: "opensah.dev/*", zone: "c9cc7f2d65239ce5c7d1eebb30f51f7c" }),
			triggers.fetch({ pattern: "www.opensah.dev/*", zone: "c9cc7f2d65239ce5c7d1eebb30f51f7c" }),
		],
	},
});
