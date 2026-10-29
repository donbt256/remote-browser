# Remote Chromium Browser

A disposable Ubuntu GitHub Actions runner hosts a full XFCE desktop with Google Chrome, exposed through a password-protected noVNC web client and a named Cloudflare Tunnel. Browser data is restored from and saved to an encrypted profile archive in a separate private GitHub repository.

- **Browser URL:** https://browser.dnly.org/
- **Main repository:** https://github.com/donbt256/remote-browser
- **Private profile repository:** https://github.com/donbt256/browser-profile-storage
- **Desktop:** XFCE + TigerVNC + noVNC + websockify
- **Browser:** Google Chrome stable

The GitHub Actions runner is temporary. The encrypted profile repository is what preserves the browser profile between runs.

## Contents

- [Architecture](#architecture)
- [Requirements](#requirements)
- [1. Prepare the main repository](#1-prepare-the-main-repository)
- [2. Create the private profile-storage repository](#2-create-the-private-profile-storage-repository)
- [3. Create the Cloudflare Tunnel and hostname](#3-create-the-cloudflare-tunnel-and-hostname)
- [4. Create the GitHub Actions secrets](#4-create-the-github-actions-secrets)
- [5. Obtain the local viewer](#5-obtain-the-local-viewer)
- [6. Start and use the browser](#6-start-and-use-the-browser)
- [7. Stop the session and save the profile](#7-stop-the-session-and-save-the-profile)
- [Persistent profile details](#persistent-profile-details)
- [Troubleshooting](#troubleshooting)
- [Security notes](#security-notes)

## Architecture

1. A manually dispatched GitHub Actions workflow checks out this repository on an Ubuntu runner.
2. It downloads the encrypted profile from the private `browser-profile-storage` repository, decrypts it using `PROFILE_ENCRYPTION_KEY`, and restores it to the container's `/config` directory.
3. Docker builds and starts the desktop image from `.docker/novnc`. Chrome uses `/config/Chromium` as its profile directory.
4. A small Node.js reverse proxy listens on runner-local port 8080. It protects the noVNC UI with `BROWSER_PASSWORD` and validates short-lived HMAC tickets for WebSocket upgrades.
5. `cloudflared` connects the runner to the named Cloudflare Tunnel. Cloudflare routes `browser.dnly.org` to `http://localhost:8080`.
6. When the workflow is stopped, its cleanup steps stop the desktop, remove stale Chrome lock files, compress and encrypt the profile, and upload `profile.tar.gz.gpg` as a release asset in the private profile repository.

The raw VNC port is not exposed publicly. Only the authenticated web proxy is routed through Cloudflare.

## Requirements

- A GitHub account with permission to configure Actions and repository secrets.
- A Cloudflare account managing the `dnly.org` domain and permission to create/manage a named Tunnel.
- A private GitHub repository to store the encrypted profile.
- A local copy of the provided noVNC viewer HTML (used to connect to the remote desktop).
- Four GitHub Actions repository secrets, described below.

No self-hosted server is required. The browser runs on a GitHub-hosted runner while the workflow is active. GitHub-hosted runner limits and usage policies apply.

## 1. Prepare the main repository

1. Open [`donbt256/remote-browser`](https://github.com/donbt256/remote-browser).
2. Confirm the default branch contains:
   - `.github/workflows/remote-browser.yml` — manually started browser session.
   - `.docker/novnc/Dockerfile` — desktop image definition.
   - `.docker/novnc/start-desktop.sh` — starts the desktop and Chrome.
3. Open **Settings → Actions → General** and ensure Actions are permitted by the repository/organization policy. The workflow uses GitHub-hosted Ubuntu runners and Docker.
4. The workflow is started manually from the Actions tab; it does not start on every push.

If setting this up in a different repository, keep the workflow and image paths intact or update the workflow references accordingly.

## 2. Create the private profile-storage repository

The workflow expects the profile repository to be named `donbt256/browser-profile-storage`.

1. Create a repository named **browser-profile-storage** under the same GitHub account.
2. Set its visibility to **Private**. Do not make it public: although the archive is encrypted, it contains browser profile data.
3. Initialize it with a README if GitHub requires an initial commit. No source code or profile file needs to be committed manually.
4. Create a token that can access this repository. For a fine-grained personal access token:
   - Resource owner: the account that owns `browser-profile-storage`.
   - Repository access: **Only select repositories** → `browser-profile-storage`.
   - Repository permissions: **Contents: Read and write** and **Metadata: Read-only**.
   - Set an expiration date you can maintain; update the GitHub secret before the token expires.
5. Copy the token value. It will be added as `PROFILE_STORAGE_TOKEN` in the next section.

The workflow uses the GitHub CLI to download and replace a GitHub Release asset. On first successful save it creates a release tagged `browser-profile`; later saves replace the asset named `profile.tar.gz.gpg`. The workflow can also import the legacy encrypted file from the repository's Git history if no release asset exists.

## 3. Create the Cloudflare Tunnel and hostname

This setup uses a **named Cloudflare Tunnel**, not a temporary trycloudflare URL. The hostname is stable between GitHub Actions runs.

1. Sign in to the Cloudflare dashboard and select the account that manages `dnly.org`.
2. Open **Networking → Tunnels** (the exact dashboard label may vary) and create a named tunnel, for example `remote-browser-github-actions`.
3. Select the connector option for a Docker/Linux or other token-based connector and copy the tunnel token. Keep it secret.
4. In the tunnel's **Public Hostnames**, **Routes**, or equivalent configuration, add a public hostname:
   - **Subdomain:** `browser`
   - **Domain:** `dnly.org`
   - **Service type:** `HTTP`
   - **Service URL:** `http://localhost:8080`
5. Save the route. If Cloudflare offers to create the DNS record, accept it. Otherwise create the required proxied DNS route for `browser.dnly.org` through that tunnel using the Cloudflare dashboard's tunnel instructions.
6. Keep the token available for the GitHub secret `CLOUDFLARE_TUNNEL_TOKEN`.

Important: `localhost:8080` means port 8080 on the GitHub Actions runner where `cloudflared` is running. Do not use the container's port 6080 as the public service. The authenticated proxy is on 8080; the noVNC service on 6080 is bound to loopback and should not be exposed directly.

If you already have a named tunnel, you can reuse it. Add or confirm the `browser.dnly.org` public-hostname route to `http://localhost:8080`, and use that tunnel's token.

## 4. Create the GitHub Actions secrets

Open the **main** repository `donbt256/remote-browser` and go to:

**Settings → Secrets and variables → Actions → New repository secret**

Create all four secrets below. Names are case-sensitive.

| Secret name | Value | Purpose |
| --- | --- | --- |
| `BROWSER_PASSWORD` | A strong password of at least 16 characters | Password for the remote browser login page |
| `PROFILE_STORAGE_TOKEN` | The GitHub token created in step 2 | Read/write access to the private profile-storage repository and its release asset |
| `PROFILE_ENCRYPTION_KEY` | A long, unique passphrase you create | Encrypts and decrypts the saved browser profile |
| `CLOUDFLARE_TUNNEL_TOKEN` | The named tunnel token from step 3 | Authenticates the Cloudflare Tunnel connector |

### Choose and preserve the encryption key

Use a long, random passphrase (preferably generated by a password manager). Save it in your password manager or another secure place. **If you lose or change `PROFILE_ENCRYPTION_KEY`, previously saved profiles cannot be decrypted.** Do not regenerate it casually, and do not commit it to the repository.

The browser password and profile encryption key are different secrets and serve different purposes. Do not reuse your GitHub token or Cloudflare token as either one.

### Verify secrets

- [ ] `BROWSER_PASSWORD` exists and is at least 16 characters.
- [ ] `PROFILE_STORAGE_TOKEN` can read and write the private `browser-profile-storage` repository.
- [ ] `PROFILE_ENCRYPTION_KEY` is saved securely and will remain stable across runs.
- [ ] `CLOUDFLARE_TUNNEL_TOKEN` belongs to the named tunnel with the hostname route configured above.

GitHub will not show a secret's value after it has been saved. If one is wrong, edit the secret and replace its value.

## 5. Obtain the local viewer

The repository includes a separate workflow for building the local noVNC viewer.

1. In `donbt256/remote-browser`, open **Actions**.
2. Select **Build Local noVNC Viewer**.
3. If it is a manually dispatched workflow, click **Run workflow** and run it on the default branch.
4. Open the completed workflow run and find its **Artifacts** section.
5. Download the `local-novnc-viewer` artifact and extract it.
6. Keep the supplied `index.html` locally. Open it in your browser when you want to connect.

The viewer is a local HTML file; it is not the browser desktop itself. It connects to the remote desktop at `https://browser.dnly.org/` and obtains the short-lived WebSocket ticket required by the proxy. If you use a different hostname, update the viewer's configured server URL to match.

Do not add your GitHub token, Cloudflare tunnel token, or profile encryption key to the viewer HTML. The viewer only needs the public browser URL and the browser password when prompted.

## 6. Start and use the browser

1. Open **Actions → Remote Chromium Browser** in `donbt256/remote-browser`.
2. Click **Run workflow**, select the default branch, and start it.
3. Open the run and wait for the browser job to finish setup. In the workflow log or run summary, look for:
   `Cloudflare Tunnel connected: https://browser.dnly.org/`
4. Open your local `index.html` viewer.
5. Connect to `https://browser.dnly.org/` if the viewer asks for the server URL.
6. Enter the `BROWSER_PASSWORD` you set in GitHub Actions secrets.
7. The remote noVNC desktop should appear, with Chrome running in the XFCE desktop.

The first run will start with a clean profile if no previous encrypted archive exists. The first successful save creates the profile release asset. Later runs restore the saved profile, including Chrome data and application configuration stored inside `/config`.

## 7. Stop the session and save the profile

When finished:

1. Return to the GitHub Actions run.
2. Use **Cancel workflow** to stop the active browser session. The workflow has an `if: always()` save step intended to run during cancellation.
3. Wait for the run to finish cancelling and inspect the final steps/logs.
4. Confirm the log reports that the encrypted browser profile was saved as a private GitHub Release asset.

Do not assume the profile saved merely because the browser tab closed. The session is running in GitHub Actions; closing the local viewer does not stop the workflow or trigger the save step.

Profile saving is best-effort. A forced runner termination, timeout, cancellation before the cleanup step can run, invalid secrets, or a failed GitHub API call can prevent the latest changes from being saved. For important sessions, stop the workflow normally and check the save log before starting another run.

Only one browser session is intended to run at a time. The workflow's concurrency group prevents a second run from being launched concurrently with the active one.

## Persistent profile details

The profile archive is stored as the `profile.tar.gz.gpg` asset attached to the `browser-profile` release in the private `donbt256/browser-profile-storage` repository.

- The archive is encrypted with GPG symmetric encryption using AES-256.
- The passphrase is `PROFILE_ENCRYPTION_KEY`.
- The release asset is replaced on each save, rather than adding a large binary to Git history.
- Cache and crash-report directories are excluded to reduce archive size.
- Stale Chrome singleton lock files are removed before restoring and after stopping Chrome.
- Existing installations with a legacy `profile.tar.gz.gpg` stored as a Git file can be migrated to the release-asset method on save.

Do not delete the `browser-profile` release, its `profile.tar.gz.gpg` asset, or the encryption key unless you intend to discard the saved profile. The profile can include cookies, active website sessions, history, extensions, and application settings. Treat the encrypted archive and its decryption key as sensitive.

## Troubleshooting

### The workflow fails because a secret is missing

- Confirm all four names in [Create the GitHub Actions secrets](#4-create-the-github-actions-secrets) are exact.
- Secret values are not available for inspection after saving; edit the secret to replace a potentially incorrect value.
- Ensure `BROWSER_PASSWORD` is at least 16 characters.

### Cloudflare Tunnel does not connect

- Confirm the token is from the intended named tunnel and was copied completely.
- Check that the tunnel is enabled and the public-hostname route is `browser.dnly.org` → `http://localhost:8080`.
- Make sure the DNS record for `browser.dnly.org` is associated with that tunnel.
- Inspect the **Start Cloudflare Tunnel** step in the Actions logs. It prints the cloudflared log if the tunnel process exits or fails to register.
- The hostname route should use HTTP to the local proxy; Cloudflare provides HTTPS at the public hostname.

### The URL loads but asks for a password repeatedly

- Make sure you are entering the GitHub secret value for `BROWSER_PASSWORD`, not the encryption key.
- Confirm the viewer is using `https://browser.dnly.org/`.
- If a browser password was changed, reload the viewer and sign in again.

### The page loads but the desktop does not appear

- Check that the Actions workflow is still running.
- Inspect the **Build and start noVNC desktop** step and the container logs.
- Check the **Start password and WebSocket-ticket proxy** step for proxy startup errors.
- Use the local viewer generated by the current **Build Local noVNC Viewer** workflow rather than an older copy.

### The profile does not persist

- Confirm the final save step ran and logged a successful upload.
- Check that `PROFILE_STORAGE_TOKEN` still has access to the private profile repository and can create/update releases.
- Verify `PROFILE_ENCRYPTION_KEY` has not changed.
- Make sure the workflow was cancelled through GitHub Actions and allowed to execute its cleanup step.
- Confirm the `browser-profile` release exists in the private profile repository and contains `profile.tar.gz.gpg`.

### The old profile file exceeds GitHub's 100 MiB Git-file limit

The current workflow stores the encrypted archive as a release asset, not a normal Git file. This avoids the per-file Git limit. If migrating an old installation, the workflow can read the legacy file and writes it as a release asset the next time a profile is saved. Ensure the token has access to the profile repository.

### The run reaches its time limit

The workflow is configured with a 350-minute job timeout. GitHub-hosted runner limits apply. Save and stop the session before the timeout where possible; do not rely on forced termination to preserve the most recent profile changes.

## Security notes

- Keep the profile-storage repository private.
- Never commit any secret, tunnel token, password, profile archive, or decrypted browser data.
- Anyone with access to the live browser URL and the browser password can control the remote desktop while the session is running. Use a strong password and do not share it casually.
- The encrypted profile can contain website session cookies and other sensitive data. Encryption does not make the decrypted profile safe to share.
- Keep `PROFILE_ENCRYPTION_KEY` backed up securely and separate from the profile archive.
- Rotate `PROFILE_STORAGE_TOKEN` and update the repository secret if it expires or is exposed.
- Revoke and replace `CLOUDFLARE_TUNNEL_TOKEN` if it is exposed.
- The tunnel token and profile-storage token belong in GitHub Actions secrets, never in the local viewer or repository files.
- GitHub-hosted runners are temporary, shared infrastructure. Do not use this setup as a guaranteed-uptime server or assume a running session survives runner termination.

## License and attribution

Review the licenses and terms for Google Chrome, noVNC, TigerVNC, XFCE, websockify, and Cloudflare Tunnel before redistributing or adapting the project.
