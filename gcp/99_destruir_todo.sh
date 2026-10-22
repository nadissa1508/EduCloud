#!/usr/bin/env bash
# Elimina TODOS los recursos del prototipo (usar al terminar el proyecto).
set -uo pipefail
source "$(dirname "$0")/config.env"
gcloud config set project "$PROJECT_ID"
gcloud compute instances delete qr-vm-ventas-01 qr-vm-ventas-02 qr-vm-ti-01 qr-vm-dc-01 qr-vm-visitas-01 --zone="$ZONE" --quiet
gcloud compute firewall-rules delete qr-fw-allow-iap-ssh qr-fw-ventas-intra qr-fw-ti-intra qr-fw-dc-intra \
  qr-fw-ti-admin qr-fw-ventas-a-dc qr-fw-visitas-deny-privadas --quiet
gcloud compute networks subnets delete qr-snet-ventas qr-snet-visitas qr-snet-ti qr-snet-dc --region="$REGION" --quiet
gcloud compute networks delete "$VPC" --quiet
