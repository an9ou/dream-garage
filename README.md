# Dream Garage

Save your dream cars, host and join car meets, and find nearby fuel stations with Hong Kong fuel prices. It's built for phones.

This folder is ready to publish free on **GitHub Pages**. Once it's online, open the link on any phone in Safari or Chrome. Everything works there, including your location, the live map and station search, and fuel prices refreshed daily.

## What's in this folder

| File | What it is |
|---|---|
| `index.html` | The whole app: pages, styles and code in one file |
| `data/prices.json` | Today's fuel prices. GitHub replaces this with a fresh copy every day |
| `scripts/update_prices.py` | The small script GitHub runs to fetch those prices |
| `.github/workflows/deploy.yml` | Tells GitHub how to publish the site (hidden folder, see step 5) |
| `manifest.webmanifest`, `icons/` | The app name and icon for "Add to Home Screen" |

## Publish it (about 10 minutes, once)

1. **Unzip** this folder on your computer.
2. **Create a repository.** Sign in at github.com (free account), click **+ → New repository**, name it `dream-garage`, keep it **Public**, don't tick any boxes, then click **Create repository**. (Free GitHub Pages needs a public repository.)
3. **Upload the files.** On the new, empty repository page, click **uploading an existing file**. Drag in everything inside the folder: `index.html`, `manifest.webmanifest`, `README.md`, and the `data`, `icons` and `scripts` folders. Click **Commit changes**.
4. **Switch Pages on.** Go to **Settings → Pages**. Under *Build and deployment*, set **Source** to **GitHub Actions**.
5. **Add the publish instructions.** Mac Finder hides folders whose names start with a dot, so the easiest way is to create this file on GitHub itself:
   - Go back to the **Code** tab, click **Add file → Create new file**.
   - In the name box type exactly `.github/workflows/deploy.yml` (the slashes create the folders).
   - Paste in everything from the box below, then click **Commit changes**.

   ```yaml
   name: Deploy Dream Garage

   on:
     push:
       branches: [main]
     schedule:
       - cron: "15 2 * * *"   # every day at 02:15 UTC = 10:15 Hong Kong time
     workflow_dispatch:

   permissions:
     contents: read
     pages: write
     id-token: write

   concurrency:
     group: pages
     cancel-in-progress: false

   jobs:
     deploy:
       runs-on: ubuntu-latest
       environment:
         name: github-pages
         url: ${{ steps.deployment.outputs.page_url }}
       steps:
         - uses: actions/checkout@v4
         - name: Fetch today's fuel prices
           run: python3 scripts/update_prices.py || echo "::warning::Price update failed - publishing the last saved prices"
         - uses: actions/configure-pages@v5
         - uses: actions/upload-pages-artifact@v3
           with:
             path: .
         - id: deployment
           uses: actions/deploy-pages@v4
   ```

6. **Wait for the green tick.** Open the **Actions** tab. A run called *Deploy Dream Garage* starts by itself and takes about a minute. When it shows a green tick, your site is live at:

   `https://YOUR-GITHUB-USERNAME.github.io/dream-garage/`

   (The same link is shown in **Settings → Pages**.)

## Open it on your phone

- Open the link in **Safari** (iPhone) or **Chrome** (Android). Don't use a preview inside a chat app or email, because those don't run the app's code.
- On the Fuel tab, tap **Allow** when it asks for your location.
- To make it feel like an app: on iPhone tap **Share → Add to Home Screen**; on Android tap **⋮ → Add to Home screen** (or **Install app**).

## Update the site later

On GitHub, click **Add file → Upload files**, drop in the new `index.html` and click **Commit changes**. GitHub publishes it again automatically in about a minute. If your phone still shows the old version, pull down to refresh.

## Where each feature gets its data

| Feature | Where it comes from | Works online? |
|---|---|---|
| Garage, car meets, calendar | Saved in each person's own browser (not shared between people yet) | Yes |
| Map | OpenStreetMap map tiles, via the Leaflet library | Yes |
| Nearby stations | OpenStreetMap search (Nominatim), with backup servers and a saved list of all 254 Hong Kong stations | Yes, live |
| Your location | The phone's GPS; needs an `https://` link and your permission | Yes |
| Fuel prices | Hong Kong Consumer Council, fetched by GitHub once a day into `data/prices.json` | Yes, refreshed daily |

Why fuel prices go through GitHub: the Consumer Council's server doesn't give web pages permission to read its data directly (the "CORS" header is missing), so any browser blocks it. The GitHub workflow fetches the prices on a server, where that rule doesn't apply, and publishes them next to your page. Browsers always allow a page to read files from its own site.

## If something goes wrong

- **The link shows "404".** Wait a minute and refresh. Check the latest run in **Actions** has a green tick, **Settings → Pages → Source** says **GitHub Actions**, and the repository is **Public**.
- **The run failed at the last step.** Pages probably wasn't switched on yet (step 4). Switch it on, then in **Actions** open the failed run and click **Re-run all jobs**.
- **The Fuel page says "the daily refresh looks paused".** GitHub pauses daily runs after 60 days with no changes to the repository. In **Actions**, choose *Deploy Dream Garage* and click **Enable workflow** (if shown), then **Run workflow**.
- **A run shows the warning "Price update failed".** The Consumer Council's server was down at that moment. The site is still published with the last saved prices, and the next day's run will try again.
- **"Use my location" doesn't work.** Make sure you opened the `https://…github.io/…` link, not the file. On iPhone check **Settings → Privacy & Security → Location Services → Safari Websites**.
