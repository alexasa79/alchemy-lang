# Alchemy-Lang website

Source for <https://alchemy-lang.org/>, built with Hugo and the PaperMod theme.

## Local preview

Install Hugo Extended 0.163.3, then run:

```sh
git submodule update --init --recursive
hugo server --buildDrafts
```

The site intentionally includes content marked as drafts, matching the original
Codeberg publishing script.

## Publishing

Pushing to `main` builds and deploys the website through GitHub Actions to GitHub
Pages. To rebuild the latest GitHub `main` without a new commit, run `./publish.sh`
with the GitHub CLI installed and authenticated. Local, unpushed changes are not
included in that rebuild.

The workflow pins Hugo 0.163.3 and verifies the downloaded archive's checksum.
The PaperMod version is pinned by the Git submodule.

The custom domain is configured in the repository's Pages settings. Cloudflare
manages DNS, with the apex and `www` CNAME records pointing to
`alexasa79.github.io` in DNS-only mode.
