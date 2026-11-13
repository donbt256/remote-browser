LOCAL noVNC VIEWER

1. Extract all files from this ZIP into one folder.
2. Open index.html in a modern browser.
3. Enter a GitHub fine-grained token with Actions: Read and write for
   donbt256/remote-browser, then click Start browser. The token is held
   in memory only and is not stored by this page.
4. Open the run link and copy its HTTPS URL from the workflow Summary.
5. Enter that URL and your BROWSER_PASSWORD secret in the local page.
6. Use Check status or Stop browser to manage the workflow run.

The viewer JavaScript is bundled locally. No iframe is used. Only the
remote desktop connection goes to the Actions runner.

Keep the GitHub Actions workflow running while connected.
