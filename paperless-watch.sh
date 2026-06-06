#!/bin/bash

PDF_DIR="/var/spool/cups-pdf/ANONYMOUS"

echo "[paperless-watch] Surveillance de $PDF_DIR"

while true; do
    inotifywait -m -e close_write --format "%f" "$PDF_DIR" 2>/dev/null | while read filename; do
        filepath="$PDF_DIR/$filename"
        echo "[paperless-watch] Nouveau fichier : $filename"
        sleep 1

        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
            -X POST "$PAPERLESS_URL/api/documents/post_document/" \
            -H "Authorization: Token $PAPERLESS_TOKEN" \
            -F "document=@$filepath" \
            -F "title=$filename")

        if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "202" ]; then
            echo "[paperless-watch] Envoyé : $filename (HTTP $HTTP_CODE)"
            [ "${PAPERLESS_DELETE,,}" != "no" ] && rm -f "$filepath"
        else
            echo "[paperless-watch] ERREUR HTTP $HTTP_CODE : $filename"
        fi
    done
    echo "[paperless-watch] inotifywait relancé..."
    sleep 5
done
