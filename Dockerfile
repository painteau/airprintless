FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      cups \
      cups-client \
      printer-driver-cups-pdf \
      avahi-daemon \
      libnss-mdns \
      inotify-tools \
      curl \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY start.sh /start.sh
COPY paperless-watch.sh /paperless-watch.sh
COPY healthcheck.sh /healthcheck.sh
RUN chmod +x /start.sh /paperless-watch.sh /healthcheck.sh

ENV TZ="Europe/Paris" \
    CUPS_ADMIN_USER="admin" \
    CUPS_ADMIN_PASSWORD="secr3t" \
    CUPS_SHARE_PRINTERS="yes" \
    CUPS_REMOTE_ADMIN="yes" \
    PRINTER_NAME="AirPrint PDF" \
    PAPERLESS_ENABLED="no" \
    PAPERLESS_URL="" \
    PAPERLESS_TOKEN=""

HEALTHCHECK --interval=15s --timeout=5s CMD /healthcheck.sh

ENTRYPOINT ["/start.sh"]
