# Local noVNC viewer

The standalone viewer package is built by GitHub Actions. It contains the HTML page and a bundled copy of the official noVNC client JavaScript, so the viewer assets are local and the page can be opened directly without an iframe or a local web server.

## Download the standalone viewer

1. Open the repository's **Actions** tab.
2. Select **Build Local noVNC Viewer**.
3. Click **Run workflow** and wait for the run to finish.
4. Download the `local-novnc-viewer` artifact and extract the ZIP.
5. Open `index.html` from the extracted folder.

The package contains `index.html`, `novnc-bundle.js`, the noVNC license, and a short README. Keep all files together.

## Connect

1. Start the **Remote Chromium Browser** workflow.
2. Copy the HTTPS URL from that workflow's summary.
3. Enter the URL and the `BROWSER_PASSWORD` secret in the local viewer.

The local page exchanges the password for a signed, short-lived WebSocket ticket. The password is not put in the URL. The ticket expires after two minutes. The remote workflow and ngrok tunnel must remain running.

## Architecture

- Local: HTML viewer and bundled noVNC JavaScript.
- Remote: Chromium, XFCE/VNC, and the WebSocket proxy on the GitHub Actions runner.
- Transport: HTTPS for ticket exchange and WSS for desktop traffic.
- No iframe is used.
