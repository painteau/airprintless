# airprintless

Virtual AirPrint printer that generates PDFs and sends them automatically to Paperless-ngx.

Print from iPhone, iPad or Mac — no physical printer needed.

## How it works

1. Your device sees an **AirPrint** printer on the network (via Bonjour/mDNS)
2. You print — CUPS receives the job and cups-pdf generates a PDF
3. If Paperless is enabled, the PDF is uploaded via API and deleted locally

## Requirements

- `network_mode: host` — required for Bonjour/mDNS discovery (AirPrint)
- The host must have an avahi-daemon running (standard on most Linux distros and UNRAID)

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
      - PRINTER_NAME=AirPrintless
      - PAPERLESS_ENABLED=no
      - PAPERLESS_URL=https://paperless.example.com
      - PAPERLESS_TOKEN=your_token_here
      - TZ=Europe/Paris
```

## Environment variables

| Variable | Default | Description |
|---|---|---|
| `CUPS_ADMIN_USER` | `admin` | CUPS web interface username |
| `CUPS_ADMIN_PASSWORD` | `secr3t` | CUPS web interface password |
| `PRINTER_NAME` | `AirPrint PDF` | Printer name shown on iPhone/iPad |
| `PAPERLESS_ENABLED` | `no` | Set to `yes` (case-insensitive) to enable auto-upload |
| `PAPERLESS_URL` | `` | Paperless-ngx base URL |
| `PAPERLESS_TOKEN` | `` | Paperless-ngx API token (Settings > API Token) |
| `PAPERLESS_DELETE` | `yes` | Delete local PDF after successful upload (`no` to keep a copy) |
| `TZ` | `Europe/Paris` | Timezone |

## Paperless-ngx integration

When `PAPERLESS_ENABLED=yes`:

- A watcher monitors the PDF output folder with `inotifywait`
- Each new PDF is uploaded via the Paperless REST API (`POST /api/documents/post_document/`)
- On success, the local PDF is deleted
- On failure, the PDF stays locally — nothing is lost
- The watcher auto-restarts if it crashes

## CUPS web interface

Access at `http://<host-ip>:631` — log in with `CUPS_ADMIN_USER` / `CUPS_ADMIN_PASSWORD`.

## Without Paperless

When `PAPERLESS_ENABLED=no`, PDFs are saved to the mounted volume (`./pdf`) and kept there.

## UNRAID template

A Community Applications-compatible template is available in the [releases](https://github.com/painteau/airprintless).

Add it via UNRAID > Docker > Add Container and search for `airprintless` in your user templates.

## Supported architectures

| Architecture | Supported |
|---|---|
| `linux/amd64` | ✓ |
| `linux/arm64` | ✓ |

## Based on

- [CUPS](https://openprinting.github.io/cups/) — printing system
- [cups-pdf](https://www.cups-pdf.de/) — virtual PDF printer backend
- [SickHub/docker-cups-airprint](https://github.com/SickHub/docker-cups-airprint) — inspiration (GPL-3.0)

## License

GPL-3.0
