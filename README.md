# remote-browser

A GitHub Actions-hosted Chromium desktop with a locally bundled noVNC viewer, password authentication, WebSocket ticket authentication, and encrypted profile persistence in the private `donbt256/browser-profile-storage` repository.

## Cloudflare Tunnel setup

The workflow uses a named Cloudflare Tunnel and the stable hostname `https://browser.dnly.org/`. The tunnel must be configured in Cloudflare before starting the workflow.

1. In the Cloudflare dashboard, open **Networking → Tunnels** and create a named tunnel, for example `remote-browser-github-actions`.
2. Open the tunnel's **Public Hostnames / Routes** configuration and add:
   - Hostname: `browser.dnly.org`
   - Service type: `HTTP`
   - Service URL: `http://localhost:8080`
3. Copy the tunnel token from Cloudflare. Do not commit it or paste it into source files.
4. In this GitHub repository, open **Settings → Secrets and variables → Actions → New repository secret**:
   - Name: `CLOUDFLARE_TUNNEL_TOKEN`
   - Value: the named tunnel token copied from Cloudflare.
5. Confirm these existing repository secrets remain configured:
   - `BROWSER_PASSWORD` — at least 16 characters
   - `PROFILE_STORAGE_TOKEN` — token that can read and write the private profile-storage repository
   - `PROFILE_ENCRYPTION_KEY` — encryption passphrase used for the profile archive
6. Run **Actions → Remote Chromium Browser → Run workflow**. The run Summary should show `https://browser.dnly.org/` after Cloudflare reports a registered tunnel connection.
7. Download the latest `local-novnc-viewer` artifact from the **Build Local noVNC Viewer** workflow and extract it. Continue using the local `index.html`; the GitHub token stays only in your local copy.

Cloudflare Tunnel supports WebSockets, required by noVNC. The tunnel token belongs in GitHub Actions secrets only. Never put it in the public repository or local viewer.

## Persistent profile

The workflow decrypts `profile.tar.gz.gpg` from the private `donbt256/browser-profile-storage` repository before starting Chromium. On workflow cleanup, it stops Chromium, removes stale singleton lock files, encrypts the profile with AES-256, and pushes the updated encrypted archive back to that private repository.

Cancel the workflow from the local viewer or GitHub Actions when finished so the cleanup step can attempt to save the profile. Profile saving is not guaranteed if a runner is forcibly terminated.
