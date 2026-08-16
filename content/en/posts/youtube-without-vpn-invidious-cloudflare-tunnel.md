+++
title = 'YouTube for Your Family in Iran, Without a VPN'
date = 2026-08-16T00:00:00+02:00
categories = ['self-hosting']
tags = ['invidious', 'cloudflare-tunnel', 'youtube', 'censorship', 'docker', 'self-hosting']
+++

YouTube is blocked in Iran, so most people there depend on VPNs that are slow,
unstable, and often blocked themselves. If you live outside Iran and have a small
computer at home, there is a nicer way: run [Invidious](https://github.com/iv-org/invidious)
(an open-source YouTube frontend) on your home connection and publish it through a
[Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/get-started/create-remote-tunnel/).

Your family just opens a normal website. No VPN, no app, no configuration on
their side.

## Why this works

- **Your home IP is a residential IP.** YouTube aggressively blocks requests
  coming from datacenters, so Invidious on a cheap VPS breaks all the time.
  From a home connection it just works.
- **Cloudflare Tunnel needs no open ports.** A small connector (`cloudflared`)
  dials *out* from your home to Cloudflare, and Cloudflare routes your public
  domain to it. Your home IP stays hidden and your router stays untouched.
- **The blocked side never talks to YouTube.** Visitors in Iran only talk to
  your domain on Cloudflare's network; your server fetches the videos.

You need: a machine at home that runs Docker (an old laptop is perfect), a free
Cloudflare account, and a domain added to Cloudflare.

## Step 1: Run Invidious with Docker

Make a folder, e.g. `/srv/invidious`, and grab the repository (only needed for
two database init files):

```bash
git clone --depth 1 https://github.com/iv-org/invidious /srv/invidious-src
mkdir /srv/invidious && cd /srv/invidious
```

Generate three random secrets (write them down for the next file):

```bash
openssl rand -hex 8   # hmac_key
openssl rand -hex 8   # companion key
openssl rand -hex 8   # db password
```

Create `docker-compose.yml`:

```yaml
services:
  invidious:
    image: quay.io/invidious/invidious:latest
    restart: unless-stopped
    ports:
      - "127.0.0.1:3000:3000"
    environment:
      INVIDIOUS_CONFIG: |
        db:
          dbname: invidious
          user: invidious
          password: "<db password>"
          host: invidious-db
          port: 5432
        check_tables: true
        invidious_companion:
          - private_url: "http://companion:8282/companion"
        invidious_companion_key: "<companion key>"
        hmac_key: "<hmac_key>"
        domain: yt.example.com
        https_only: true
        external_port: 443
    depends_on:
      invidious-db:
        condition: service_healthy

  companion:
    image: quay.io/invidious/invidious-companion:latest
    environment:
      - SERVER_SECRET_KEY=<companion key>
    restart: unless-stopped
    cap_drop: [ALL]
    read_only: true
    volumes:
      - companioncache:/var/tmp/youtubei.js:rw
    security_opt:
      - no-new-privileges:true

  invidious-db:
    image: docker.io/library/postgres:14
    restart: unless-stopped
    volumes:
      - postgresdata:/var/lib/postgresql/data
      - /srv/invidious-src/config/sql:/config/sql
      - /srv/invidious-src/docker/init-invidious-db.sh:/docker-entrypoint-initdb.d/init-invidious-db.sh
    environment:
      POSTGRES_DB: invidious
      POSTGRES_USER: invidious
      POSTGRES_PASSWORD: "<db password>"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $$POSTGRES_USER -d $$POSTGRES_DB"]

  cloudflared:
    image: cloudflare/cloudflared:latest
    restart: unless-stopped
    network_mode: host
    command: tunnel run --token ${TUNNEL_TOKEN}
    depends_on:
      - invidious

volumes:
  postgresdata:
  companioncache:
```

Replace the three secrets and `yt.example.com` with your own values. Don't start
it yet, because the tunnel token comes next.

## Step 2: Create the Cloudflare Tunnel

In the [Cloudflare dashboard](https://one.dash.cloudflare.com/):

1. Go to **Networking → Tunnels → Create a tunnel** and pick the
   **Cloudflared** connector. Give it a name.
2. Cloudflare shows an install command containing a long **token**
   (`eyJ...`). Copy just the token and save it next to your compose file:

   ```bash
   echo "TUNNEL_TOKEN=eyJ..." > /srv/invidious/.env
   chmod 600 /srv/invidious/.env
   ```

3. In the tunnel's **Routes** tab, add a published application:
   your subdomain (e.g. `yt.example.com`) → service `http://localhost:3000`.

Now start everything:

```bash
docker compose up -d
```

One detail matters here: `cloudflared` runs with `network_mode: host`, so that
`localhost:3000` in the route really means your server. On Docker's default
network the tunnel would try to connect to *itself* and fail with
"connection refused". I learned this the hard way.

Open `https://yt.example.com` and you should see Invidious, served from your
home, with a valid certificate, on any network.

## Step 3: Decide who can use it

The site is now public. Two easy options:

- **Keep it open but quiet:** add `registration_enabled: false` to
  `INVIDIOUS_CONFIG` after creating accounts for your family, and simply don't
  share the URL. Anyone with the link can still watch.
- **Lock it with Cloudflare Access (recommended):** in Zero Trust, create an
  Access application for your hostname and an *Allow* policy whose **Include**
  rule lists your family's email addresses. They log in once (email code or
  Google) and stay logged in for the session length you choose.

  One trap: Access *Include* rules are OR-ed. If you add "Login method: Google"
  as an Include, **every Google account in the world** matches. Keep only
  *Emails* under Include; put login-method conditions under *Require*.

## Maintenance

Almost none. Updates are:

```bash
cd /srv/invidious && docker compose pull && docker compose up -d
```

If playback stops working someday, restart the stack first. YouTube changes
things regularly and the Invidious images update quickly in response.

That's the whole setup: one old laptop, one free tunnel, and your family
watches YouTube in the browser like the block doesn't exist.
