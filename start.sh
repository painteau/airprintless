#!/bin/bash
set -e

PDF_DIR="/var/spool/cups-pdf/ANONYMOUS"
mkdir -p "$PDF_DIR"
chmod 777 "$PDF_DIR"

# Créer l'utilisateur admin CUPS
if ! id "$CUPS_ADMIN_USER" &>/dev/null; then
    useradd -r -G lpadmin "$CUPS_ADMIN_USER"
fi
echo "$CUPS_ADMIN_USER:$CUPS_ADMIN_PASSWORD" | chpasswd

# Configuration CUPS
cat > /etc/cups/cupsd.conf <<EOF
LogLevel warn
MaxLogSize 0
AccessLog stderr
ErrorLog stderr
PageLog stderr
Listen 0.0.0.0:631
Listen /run/cups/cups.sock
ServerName $(hostname)
ServerAdmin $CUPS_ADMIN_USER
DefaultAuthType Basic

WebInterface Yes
DefaultEncryption Never
BrowseLocalProtocols dnssd
DNSSDBrowseWebIF Yes

<Location />
  Order allow,deny
  Allow all
</Location>

<Location /admin>
  Order allow,deny
  Allow all
</Location>

<Location /admin/conf>
  AuthType Default
  Require user @SYSTEM
  Order allow,deny
  Allow all
</Location>

<Policy default>
  <Limit Send-Document Send-URI Hold-Job Release-Job Restart-Job Purge-Jobs Set-Job-Attributes Create-Job-Subscription Renew-Subscription Cancel-Subscription Get-Notifications Reprocess-Job Cancel-Current-Job Suspend-Current-Job Resume-Job CUPS-Move-Job CUPS-Get-Document>
    Require user @OWNER @SYSTEM
    Order deny,allow
  </Limit>
  <Limit All>
    Order deny,allow
  </Limit>
</Policy>
EOF

# cups-pdf : sortie dans PDF_DIR pour tous les utilisateurs
sed -i "s|^Out .*|Out $PDF_DIR|" /etc/cups/cups-pdf.conf 2>/dev/null || true

# Avahi
sed -i 's/#enable-dbus=yes/enable-dbus=no/' /etc/avahi/avahi-daemon.conf
sed -i 's/use-ipv6=yes/use-ipv6=no/' /etc/avahi/avahi-daemon.conf
mkdir -p /run/avahi-daemon
avahi-daemon --daemonize --no-drop-root

# Démarrer CUPS en fond pour configurer l'imprimante
cupsd
echo "[airprintless] Attente CUPS..."
until curl -sf http://localhost:631/ > /dev/null 2>&1; do sleep 1; done
echo "[airprintless] CUPS prêt"

# Ajouter l'imprimante PDF
lpadmin -p PDF \
    -P /usr/share/ppd/cups-pdf/CUPS-PDF_noopt.ppd \
    -v cups-pdf:/ \
    -E \
    -o printer-is-shared=true \
    -D "${PRINTER_NAME:-AirPrint PDF}"

cupsaccept PDF
cupsenable PDF

# Générer le fichier service Avahi pour AirPrint
mkdir -p /etc/avahi/services
cat > /etc/avahi/services/airprintless.service <<AVAHI
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
  <name replace-wildcards="yes">${PRINTER_NAME:-AirPrint PDF} @ %h</name>
  <service>
    <type>_ipp._tcp</type>
    <subtype>_universal._sub._ipp._tcp</subtype>
    <port>631</port>
    <txt-record>txtvers=1</txt-record>
    <txt-record>qtotal=1</txt-record>
    <txt-record>rp=printers/PDF</txt-record>
    <txt-record>ty=${PRINTER_NAME:-AirPrint PDF}</txt-record>
    <txt-record>adminurl=http://localhost:631/printers/PDF</txt-record>
    <txt-record>note=Virtual PDF Printer</txt-record>
    <txt-record>priority=0</txt-record>
    <txt-record>pdl=application/octet-stream,application/pdf,application/postscript,image/jpeg,image/png,image/urf</txt-record>
    <txt-record>URF=W8,SRGB24,CP255,RS600</txt-record>
    <txt-record>Color=T</txt-record>
    <txt-record>Duplex=F</txt-record>
    <txt-record>Fax=F</txt-record>
    <txt-record>Scan=F</txt-record>
    <txt-record>copies=T</txt-record>
  </service>
</service-group>
AVAHI

# Relancer avahi pour prendre en compte le service
pkill avahi-daemon || true
sleep 1
avahi-daemon --daemonize --no-drop-root

echo "[airprintless] CUPS prêt — imprimante PDF configurée"
echo "[airprintless] Interface web : http://$(hostname -i):631"

# Lancer le watcher Paperless en fond
if [ "$PAPERLESS_ENABLED" = "yes" ]; then
    /paperless-watch.sh &
    echo "[airprintless] Watcher Paperless démarré"
fi

# CUPS en premier plan
pkill cupsd || true
sleep 1
exec cupsd -f
