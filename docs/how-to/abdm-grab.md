# abdm-grab — queue download links into AB Download Manager

`scripts/abdm-grab` pulls download links out of a page, resolves each one to a
direct download, and adds them all to one AB Download Manager queue.

```
abdm-grab 'https://paste.fitgirl-repacks.site/?<id>#<key>'
```

With no options it runs the whole flow: extract the links, resolve them,
confirm a queue name (defaulted from the filenames), ask for a download folder
once, then add everything to that queue. `--help` lists every option.

## Layout

The entry point is a thin script; the work lives in `scripts/abdm-grab.d/`.

| path | role |
|---|---|
| `cli.js` | argument parsing and the five-stage pipeline |
| `sources/` | **what kind of page is this** — how links are pulled out |
| `hosts/` | **what kind of file host is this** — how a landing page becomes a direct URL |
| `lib/` | HTTP (with a DoH fallback), Chrome cookies, ABDM API, prompts, naming |

Pipeline: **source** → **filter** → **resolve** → **plan** (queue name, folder)
→ **apply** (create the queue, add the downloads).

### Adding a source or a host

Both are drop-in modules registered in their directory's `index.js`, where the
first `match()` that returns true wins and the catch-all stays last.

```js
// sources/<name>.js
module.exports = { name, description, match(url, parsed), async extract(url, ctx) };
//   -> { title, links: [url], pageUrl }

// hosts/<name>.js
module.exports = { name, description, match(url, parsed), async resolve(link, ctx) };
//   -> one of the shapes in hosts/common.js `result`
```

A host resolver reports one of: `direct` (a real file URL), `passthrough`
(unresolved, ABDM gets the landing page), `challenge` (needs a browser),
`dead` (the host says the file is gone), or `error`. The CLI downgrades any
`direct` result whose URL is unchanged, so a resolver cannot silently queue an
HTML page as if it were the file.

## Supported hosts, and what actually works

| host | status |
|---|---|
| `fuckingfast.co` | **Works**, after one manual Turnstile solve — see below. |
| `datanodes.to` | **Cannot be resolved from the CLI.** Needs a fresh Turnstile token per file, with no session cookie that substitutes for it. |
| anything else | Probed with a ranged GET; direct file URLs pass straight through. |

### fuckingfast.co

The DOWNLOAD button is htmx: `POST /f/<id>/go`, guarded by
`click[!!window.turnstileToken || !!window.dlCleared]`. The page states the
mechanic outright — *"First click - open ads. Second - start download"*. A
successful POST answers `200 OK` with the direct URL in an **`HX-Redirect`**
header.

Two independent Cloudflare mechanisms are in play:

1. **The managed challenge on the site.** No cookie gets Node past it, because
   Cloudflare fingerprints the TLS handshake — a *valid* `cf_clearance` still
   returns "Just a moment...". Verified: identical cookies and full Chrome
   client hints gave 403 from Node and 200 from `curl-impersonate`. Hence
   `lib/impersonate.js`.
2. **Turnstile on the download itself.** Solving it once in Chrome sets a
   `dlpass` cookie, and every later file resolves from the CLI with no further
   clicking. When `dlpass` is absent the POST answers
   `403 captcha verification failed`, and the tool says so.

So the working routine is: `--open-site`, click DOWNLOAD twice on the page that
opens (first click eats the ad popunder), then re-run normally.

The signed `dl.fuckingfast.co` URLs are **reusable but short-lived** — good
immediately, 404 several minutes later. They need no cookies, so ABDM downloads
them plainly, but a queue left paused will wake up to 404s. The tool detects
this and offers to start the queue at once; otherwise re-run to mint fresh links.

### datanodes.to

`<download-countdown>` carries a server-issued `rand`, the countdown length and
`has-captcha="true"`. Reposting `op=download2` with that token answers
`message="Wrong captcha"` unless a Turnstile token accompanies it. The widget is
invisible and auto-solves in a real browser, which is why the page merely shows
a "Free Download" button that starts a counter — but that token cannot be
produced outside a browser. These links are reported as blocked; the tool offers
to open them in Chrome, where ABDM's extension picks the download up.

## Cookies (Chrome only)

Cloudflare-protected hosts need cookies from a real browser session, so they
are read from Chrome along with the matching User-Agent
(`~/.config/google-chrome`, all profiles, `Default` first). Cookie values are
AES-128-CBC encrypted; the key comes from gnome-keyring via `secret-tool`, with
the hardcoded `peanuts` password as a fallback. Requires `sqlite3` on PATH.

Other browsers are deliberately not supported.

## Queues

ABDM has no API for creating queues (`/queue/add`, `/queues/add`, `/add-queue`
and `/create-queue` all 404), so a queue is created by writing
`~/.abdm/config/download_db/queues/<id>.json`. ABDM rewrites those files on
exit, so the tool **stops ABDM, writes the file, and restarts it** — it asks
first. An existing queue whose name matches is reused instead, with no restart.

Deleting a queue is not automated: remove it in the ABDM UI, since downloads
reference it by id.

## ISP DNS interference

File hosts have been observed resolving to an Airtel RPZ sinkhole
(`restricted.rpz.airtelspam.com`), where every connection hangs. `lib/doh.js`
detects that — by reverse-DNS, or by a connection timing out — and retries over
DNS-over-HTTPS, connecting to the real address while keeping the hostname for
SNI and certificate validation. Disable with `--no-doh`.

## Requirements

- AB Download Manager running, with **Settings → Integration → Enable API**.
- `sqlite3` on PATH for cookie extraction.
- `abdownloadmanager-cli` for starting/restarting ABDM (queue creation).
- `curl-impersonate` for Cloudflare-protected hosts (in `home/base.nix`).
  Override the binary with `ABDM_GRAB_CURL=/path/to/curl_chrome146`.
