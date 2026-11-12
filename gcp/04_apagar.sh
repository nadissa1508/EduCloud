#!/usr/bin/env bash
# Detiene TODAS las instancias encendidas del proyecto (deja de cobrar CPU/RAM; el disco sigue cobrando centavos al mes).
set -euo pipefail
source "$(dirname "$0")/config.env"
gcloud config set project "$PROJECT_ID"
ENCENDIDAS=$(gcloud compute instances list --filter="status=RUNNING" --format="value(name)")
if [ -z "$ENCENDIDAS" ]; then echo "No hay VMs encendidas."; exit 0; fi
echo ">> Apagando: $ENCENDIDAS"
gcloud compute instances stop $ENCENDIDAS --zone="$ZONE"
# Para volver a encender una o varias:
# gcloud compute instances start qr-vm-ventas-01 qr-vm-dc-01 --zone="$ZONE"
