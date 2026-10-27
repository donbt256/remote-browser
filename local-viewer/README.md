# Local noVNC viewer

This directory contains a local HTML client for the remote Chromium desktop. It does not use an iframe. The desktop itself continues to run in the GitHub Actions runner.

## One-time setup

1. Download this repository to your computer.
2. Open PowerShell in this `local-viewer` directory and run:

   ```powershell
   .\download-novnc.ps1
   ```

   This downloads the official noVNC release source into `vendor/noVNC`.

3. Serve this directory over localhost. Modern browsers block JavaScript ES-module imports from `file://`, so opening `index.html` directly will not work. If Python is installed, run this from the `local-viewer` directory:

   ```sh
   python -m http.server 8000
   ```

   Then open `http://localhost:8000/`. Stop the local server with Ctrl+C when finished.

## Connect

1. Start the **Remote Chromium Browser** workflow in GitHub Actions.
2. Copy the HTTPS URL from the workflow summary.
3. Enter that URL and the `BROWSER_PASSWORD` secret on the local page.

The page sends the password to the HTTPS endpoint to exchange it for a short-lived ticket. The ticket is used for the WebSocket connection and expires after two minutes. The password is not placed in the URL. Do not share the ticket or remote URL while the session is active.

## Notes

- The local viewer files are stored on your computer after setup; only the remote desktop traffic connects to the Actions runner.
- The GitHub Actions runner and ngrok tunnel must remain running.
- The viewer connects directly to the remote WebSocket endpoint. No iframe is used.
- The client requires a modern browser and localhost HTTP serving because noVNC uses JavaScript ES modules.
