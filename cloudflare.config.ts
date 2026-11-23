import { defineConfig } from "cf/config";

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
	},
});
