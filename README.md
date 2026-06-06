# airprintless

Virtual AirPrint printer that generates PDFs and optionally sends them to Paperless-ngx.

Print from iPhone, iPad or Mac — no physical printer needed.

## How it works

1. Your device sees an AirPrint printer on the network (via Avahi/Bonjour)
2. You print — CUPS receives the job and cups-pdf generates a PDF
3. If Paperless is enabled, the PDF is uploaded via API and deleted locally

## Quick start

```yaml
services:
  airprintless:
    image: ghcr.io/painteau/airprintless:latest
    container_name: airprintless
    network_mode: host
    restart: unless-stopped
    volumes:
      - ./pdf:/var/spool/cups-pdf/ANONYMOUS
    environment:
      - CUPS_ADMIN_USER=admin
      - CUPS_ADMIN_PASSWORD=secr3t
      - PAPERLESS_ENABLED=no        # yes to enable auto-upload
      - PAPERLESS_URL=https://paperless.example.com
      - PAPERLESS_TOKEN=your_token_here
```

> `network_mode: host` is required for Bonjour/mDNS discovery to work.

## Environment variables

| Variable | Default | Description |
|---|---|---|
| `CUPS_ADMIN_USER` | `admin` | CUPS web interface username |
| `CUPS_ADMIN_PASSWORD` | `secr3t` | CUPS web interface password |
| `PAPERLESS_ENABLED` | `no` | Set to `yes` to enable Paperless upload |
| `PAPERLESS_URL` | `` | Paperless-ngx base URL |
| `PAPERLESS_TOKEN` | `` | Paperless-ngx API token |
| `TZ` | `Europe/Paris` | Timezone |

## CUPS web interface

Access at `http://<host-ip>:631`

## PDFs without Paperless

When `PAPERLESS_ENABLED=no`, PDFs are saved to the mounted volume (`./pdf`).

## Supported architectures

- `linux/amd64`
- `linux/arm64`
