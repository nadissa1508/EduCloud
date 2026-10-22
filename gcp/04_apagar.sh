#!/usr/bin/env bash
# Detiene las instancias (deja de cobrar CPU/RAM; el disco sigue cobrando centavos al mes).
set -euo pipefail
source "$(dirname "$0")/config.env"
gcloud config set project "$PROJECT_ID"
gcloud compute instances stop qr-vm-ventas-01 qr-vm-ventas-02 qr-vm-ti-01 qr-vm-dc-01 qr-vm-visitas-01 --zone="$ZONE"
# Para volver a encenderlas:
# gcloud compute instances start qr-vm-ventas-01 qr-vm-ventas-02 qr-vm-ti-01 qr-vm-dc-01 qr-vm-visitas-01 --zone="$ZONE"
