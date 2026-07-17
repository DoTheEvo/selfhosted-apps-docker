# hivekeep

###### guide-by-example

![logo](https://i.imgur.com/u5LH0jI.png)

# Purpose & Overview

* [Hivekeep](https://github.com/MarlBurroW/hivekeep)

Hivekeep is a self-hosted platform to run a team of specialized AI agents.
Agents have persistent memory, a web UI, and can collaborate, build their own
tools, mini-apps and plugins. They are reachable over Telegram, Slack, Discord
and Matrix. It ships as a single container (Bun + SQLite), so it runs happily on
a small box or a Raspberry Pi.

* MIT licensed, no external database to run, all data stays on your host.
* Bring your own model provider (OpenAI, Anthropic, Gemini, Ollama, and more).

---

# Files & Directory Structure

```
/home/
└── ⊕ docker/
    └── ⊕ hivekeep/
        └── 🗎 docker-compose.yml
```

* `docker-compose.yml` - a docker compose configuration file, telling docker
  how to run the container.

The `hivekeep-data` named volume holds the SQLite database, the encryption key
and uploaded files.

# docker-compose

`docker-compose.yml`
```yml
services:
  hivekeep:
    image: ghcr.io/marlburrow/hivekeep:latest
    container_name: hivekeep
    ports:
      - "3000:3000"
    volumes:
      - hivekeep-data:/app/data
    environment:
      - PORT=3000
      - HOST=0.0.0.0
      - HIVEKEEP_DATA_DIR=/app/data
      - ENCRYPTION_KEY=${ENCRYPTION_KEY:-}
      - LOG_LEVEL=info
      # Public-facing URL, needed for webhooks and invitations
      # - PUBLIC_URL=https://hivekeep.example.com
    restart: unless-stopped

volumes:
  hivekeep-data:
```

The `ENCRYPTION_KEY` is used to encrypt secrets at rest (provider API keys,
channel tokens). Generate a stable one and keep it. If you lose it, the
encrypted values can no longer be decrypted.

```bash
ENCRYPTION_KEY=$(openssl rand -hex 32) docker compose up -d
```

To keep the key across restarts, write it once into an `.env` file next to the
compose file:

```bash
echo "ENCRYPTION_KEY=$(openssl rand -hex 32)" > .env
docker compose up -d
```

# First run

Open `http://your-server-ip:3000` in a browser. The first visit runs an
onboarding flow:

* create the admin user,
* add at least one model provider (paste an API key, or point it at a local
  Ollama endpoint),
* the platform creates a first agent you can immediately chat with.

From the web UI you can then spin up more specialized agents, schedule cron
tasks, connect messaging channels, and install plugins / mini-apps.

# Reverse proxy

If you use the Caddy setup from this repo, a minimal block is:

```
hivekeep.{$MY_DOMAIN} {
    reverse_proxy hivekeep:3000
}
```

Set `PUBLIC_URL=https://hivekeep.your-domain` in the compose environment so that
webhooks and invitation links use the right address.

# Update

```bash
docker compose pull
docker compose up -d
```

# Backup

Everything lives in the `hivekeep-data` volume. Stop the container and back up
the volume (or just the SQLite file inside it) with your usual tool, for example
[kopia](../kopia_backup/) or [borg](../borg_backup/).
