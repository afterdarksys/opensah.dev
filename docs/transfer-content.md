# Transfer documentation maintenance

Added October 22, 2026. Entry point: `site/transfer/index.html`.

The site remains static HTML with no new build/runtime dependencies. Curated
pages cover selection, human/agent workflows, the control API, compatibility,
security, failure semantics and experimental scope. Reference pages reproduce
source Markdown snapshots, also published for download. `sources.json` records
source repository, path, HEAD revision and SHA-256 of the exact copied bytes.

Refresh the Markdown and rendered HTML together when the owning protocol changes.
Review source changes before publishing: do not copy credentials, deployment
addresses, private customer details, or unreviewed implementation claims. Preserve
fenced code and tables, use one page h1, add scoped table headers and scroll
containers, and check local links/anchors with `npm run check`. Keep the sitemap
and transfer navigation in sync. Python-Markdown was used to render the initial
snapshots; it is not a dependency for serving or validating the website.

## Sources and limits

- sahxfer: PROTOCOL.md, docs/performance.md, docs/durable-streams.md; README.md,
  docs/design.md, docs/platform-roadmap.md and CLI source inform curated pages.
- sahsync: docs/usage.md and docs/paths.md.
- systemapi.io: docs/sah-file-protocol.md, reproduced without changing its source.

The file contract header says phase 0/unimplemented while the published suite
calls sahsync available. The file-protocol page explicitly records that mismatch.
Do not resolve it by editing systemapi.io from this website task or claiming a
verified deployment. Some older sahxfer design prose similarly predates the
current helper implementation. The pages distinguish library/CLI support from
server and agent deployment.

No complete cross-version or Go/Rust interoperability matrix is asserted.
Benchmark numbers are attributed source measurements, not rerun results or
competitor comparisons. Streaming is a local storage prototype with a proposed
network contract, not a public service. Universal speed, exactly-once processing,
or compliance claims are not supported by this work.

This addition covers the transfer subsystem. It does not claim to finish all
SystemAPI/ComputeAPI APIs or every ecosystem protocol. Terminal/TCP/mesh and other
API families need separate source audits before a complete ecosystem reference
can be claimed.

Publishing is separate from a Git push; see README.md and scripts/deploy-pages.sh.
