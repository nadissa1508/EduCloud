#!/usr/bin/env bash
# Crea 5 instancias e2-micro SIN IP publica, con IP interna fija y etiqueta (tag) de su segmento.
set -euo pipefail
source "$(dirname "$0")/config.env"
gcloud config set project "$PROJECT_ID"

crear_vm () {  # nombre subred ip etiqueta
  gcloud compute instances create "$1" \
    --zone="$ZONE" --machine-type="$MACHINE_TYPE" \
    --subnet="$2" --private-network-ip="$3" --no-address \
    --tags="$4" --labels="proyecto=redes-fase1,segmento=$4" \
    --image-family="$IMAGE_FAMILY" --image-project="$IMAGE_PROJECT" \
    --boot-disk-size=10GB --boot-disk-type=pd-standard \
    --shielded-secure-boot
}

crear_vm qr-vm-ventas-01  qr-snet-ventas  "$IP_VENTAS_01"  ventas
crear_vm qr-vm-ventas-02  qr-snet-ventas  "$IP_VENTAS_02"  ventas
crear_vm qr-vm-ti-01      qr-snet-ti      "$IP_TI_01"      ti
crear_vm qr-vm-dc-01      qr-snet-dc      "$IP_DC_01"      dc
crear_vm qr-vm-visitas-01 qr-snet-visitas "$IP_VISITAS_01" visitas

gcloud compute instances list --filter="labels.proyecto=redes-fase1"
