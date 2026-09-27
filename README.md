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
| `setup/deploy.yml` | A visible copy of the same file, to copy from in step 5 |
| `setup/supabase-meets.sql` | Creates the shared car-meet tables in Supabase (see *Share car meets*) |
| `supabase-config.js` | Your Supabase settings for real accounts (see *Switch on real accounts*) |
| `manifest.webmanifest`, `icons/` | The app name and icon for "Add to Home Screen" |

## Publish it (about 10 minutes, once)

1. **Unzip** this folder on your computer.
2. **Create a repository.** Sign in at github.com (free account), click **+ → New repository**, name it `dream-garage`, keep it **Public**, don't tick any boxes, then click **Create repository**. (Free GitHub Pages needs a public repository.)
3. **Upload the files.** On the new, empty repository page, click **uploading an existing file**. Drag in everything inside the folder: `index.html`, `supabase-config.js`, `manifest.webmanifest`, `README.md`, and the `data`, `icons`, `scripts` and `setup` folders. Click **Commit changes**.
4. **Switch Pages on.** Go to **Settings → Pages**. Under *Build and deployment*, set **Source** to **GitHub Actions**.
5. **Add the publish instructions.** Mac Finder hides folders whose names start with a dot, so the easiest way is to create this file on GitHub itself:
   - On your computer, open `setup/deploy.yml` from this folder in TextEdit or Notepad, select everything and copy it. (Copy from that file, not from this README: copying from a formatted page can add extra marks and spaces that break it.)
   - On GitHub, go to the **Code** tab and click **Add file → Create new file**.
   - In the name box type exactly `.github/workflows/deploy.yml` (the slashes create the folders).
   - Paste, and check that the very first line starts with `#` with no spaces in front of it. Then click **Commit changes**.

6. **Wait for the green tick.** Open the **Actions** tab. A run called *Deploy Dream Garage* starts by itself and takes about a minute. When it shows a green tick, your site is live at:

   `https://YOUR-GITHUB-USERNAME.github.io/dream-garage/`

   (The same link is shown in **Settings → Pages**.)

## Open it on your phone

- Open the link in **Safari** (iPhone) or **Chrome** (Android). Don't use a preview inside a chat app or email, because those don't run the app's code.
- On the Fuel tab, tap **Allow** when it asks for your location.
- To make it feel like an app: on iPhone tap **Share → Add to Home Screen**; on Android tap **⋮ → Add to Home screen** (or **Install app**).

## Switch on real accounts (Supabase, about 10 minutes)

Until you do this, the site uses a demo login that only saves a name in each person's browser. With Supabase, everyone gets a real account (email and password) that works on any device.

1. **Create a project.** Go to supabase.com, sign up free, and click **New project**. Name it `dream-garage`, choose a database password (save it somewhere safe), pick the **Singapore** region (closest to Hong Kong), and create it. It takes about a minute to start.
2. **Tell Supabase where your site lives.** Open **Authentication → URL Configuration**:
   - **Site URL:** `https://YOUR-GITHUB-USERNAME.github.io/dream-garage/`
   - **Redirect URLs:** click **Add URL** and add `https://YOUR-GITHUB-USERNAME.github.io/dream-garage/**`

   Email links (confirming an account, resetting a password) only work for addresses listed here.
3. **Decide about email confirmation.** Supabase's built-in email service only sends to people on your Supabase team, and only 2 emails an hour, so your friends won't receive confirmation emails from it. For testing with friends:
   - Open **Authentication → Sign In / Providers → Email** and switch **Confirm email** off. New accounts then work straight away.
   - Password-reset emails still won't reach your friends. To send real emails later, connect a free email service under **Authentication → Emails → SMTP Settings** (for example Resend, which has a free plan and works with your own domain). Then you can switch **Confirm email** back on.
4. **Copy your keys.** Open **Project Settings → API Keys** (or click **Connect** at the top). Copy the **Project URL** and the **publishable** key, which starts with `sb_publishable_`. **Never use the secret key** (`sb_secret_…`, or the old `service_role` key). This file is public, and the secret key would give anyone full control of your project.
5. **Paste them into the site.** On GitHub, open `supabase-config.js`, click the **pencil**, paste the two values between the quotes, and click **Commit changes**. The site republishes in about a minute.
6. **Try it.** Open the site, tap **Log in / Sign up → Create account**, and make an account. You'll see it under **Authentication → Users** in Supabase.

## Share car meets (Supabase, about 2 minutes)

After accounts are working, this puts car meets and RSVPs in your Supabase database, so everyone sees the same calendar.

1. In Supabase, open **SQL Editor → New query**.
2. On your computer, open `setup/supabase-meets.sql` from this folder in TextEdit or Notepad, select everything and copy it.
3. Paste it into the SQL Editor and click **Run**. You should see *Success*. It's safe to run again later.
4. Open your site's **Events** tab. Host a test meet, then open the site on another phone or browser with a different account: it's there.

What the script sets up, enforced by the database itself:

| Who | Can |
|---|---|
| Anyone, even logged out | See meets and how many people are going |
| Logged-in users | Host meets, RSVP (only for themselves) and see who's going |
| The host of a meet | Edit or cancel it (cancelling also removes its RSVPs) |
| Nobody | Host in someone else's name, change someone else's RSVP, date a meet in the past, or go over a meet's capacity |

You can see the data any time in Supabase under **Table Editor → events** and **rsvps**. Each person's **garage** (saved cars) is still kept in their own browser.

## Update the site later

On GitHub, click **Add file → Upload files**, drop in the new `index.html` and click **Commit changes**. GitHub publishes it again automatically in about a minute. If your phone still shows the old version, pull down to refresh.

## Where each feature gets its data

| Feature | Where it comes from | Works online? |
|---|---|---|
| Accounts | Supabase Auth (once `supabase-config.js` is filled in) | Yes |
| Car meets, RSVPs, calendar | Your Supabase database (once `setup/supabase-meets.sql` has been run); otherwise each browser | Yes, shared |
| Garage (saved cars) | Each person's own browser | Yes |
| Map | OpenStreetMap map tiles, via the Leaflet library | Yes |
| Nearby stations | OpenStreetMap search (Nominatim), with backup servers and a saved list of all 254 Hong Kong stations | Yes, live |
| Your location | The phone's GPS; needs an `https://` link and your permission | Yes |
| Fuel prices | Hong Kong Consumer Council, fetched by GitHub once a day into `data/prices.json` | Yes, refreshed daily |

Why fuel prices go through GitHub: the Consumer Council's server doesn't give web pages permission to read its data directly (the "CORS" header is missing), so any browser blocks it. The GitHub workflow fetches the prices on a server, where that rule doesn't apply, and publishes them next to your page. Browsers always allow a page to read files from its own site.

## If something goes wrong

- **The link shows "404".** Wait a minute and refresh. Check the latest run in **Actions** has a green tick, **Settings → Pages → Source** says **GitHub Actions**, and the repository is **Public**.
- **A run failed (red ✗).** Click the failed run and read the red message at the top — the first step, *Check the setup*, says exactly what to fix (Pages switched off, set to "Deploy from a branch", private repository, or files uploaded inside a folder). Fix it, then click **Re-run all jobs**.
- **"Invalid workflow file".** The workflow text was changed while pasting. Open `.github/workflows/deploy.yml`, click the pencil, select everything, paste the contents of `setup/deploy.yml` again, and commit. The first line must start with `#`, with no spaces or ` ``` ` marks.
- **The Fuel page says "the daily refresh looks paused".** GitHub pauses daily runs after 60 days with no changes to the repository. In **Actions**, choose *Deploy Dream Garage* and click **Enable workflow** (if shown), then **Run workflow**.
- **A run shows the warning "Price update failed".** The Consumer Council's server was down at that moment. The site is still published with the last saved prices, and the next day's run will try again.
- **Sign-up says "We sent a confirmation link", but the email never arrives.** That's Supabase's built-in email limit (step 3 of *Switch on real accounts*). Switch **Confirm email** off, or connect your own email service.
- **An email link opens an error page or "localhost".** The **Site URL** and **Redirect URLs** in Supabase don't match your GitHub link yet (step 2).
- **The Events tab says "The shared meets aren't set up yet".** Run `setup/supabase-meets.sql` in the Supabase SQL Editor (see *Share car meets*).
- **"Sorry, this meet is full".** The meet has reached its capacity. The host can raise it by editing the meet in **Table Editor → events**.
- **"The Supabase settings look wrong".** Check `supabase-config.js`: the URL should look like `https://abcd….supabase.co`, and the key should start with `sb_publishable_`.
- **"Use my location" doesn't work.** Make sure you opened the `https://…github.io/…` link, not the file. On iPhone check **Settings → Privacy & Security → Location Services → Safari Websites**.
