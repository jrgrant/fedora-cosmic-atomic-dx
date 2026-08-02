# VS Code Install Strategy

**Decision (2026-07-16)**: Revert from custom `~/.opt` tarball install to
`brew install --cask visual-studio-code-linux`.

**Rationale**:

The custom `~/.opt/VSCode-linux-x64` install was intended to provide a
self-updating VS Code independent of brew. However:

1. It did not solve the keyring/credential persistence issue — that's a
   COSMIC desktop integration problem, not an install-method problem.
2. The brew cask version is simpler: one command, auto-updates via `brew upgrade`,
   proper desktop file with correct `Exec=` path, no shell wrapper needed.
3. The custom install requires manual desktop file creation, icon extraction,
   flag wrangling (`--no-sandbox`), and PATH management — all of which brew
   handles automatically.
4. The brew layer is already in the image for other packages (starship, atuin,
   etc.) — we're not avoiding a dependency by going custom.

**Trade-off**: Brew installs into `/home/linuxbrew/` which is separate from
the user's `/var/home/`. After a rebase, brew packages may need reinstalling.
But the `ujust bootstrap` recipe already reinstalls brew packages — this is
handled.

**For next build**: Remove the VS Code `~/.opt` install block from bootstrap
and reinstate `brew install --cask visual-studio-code-linux`.
