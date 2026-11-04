#!/usr/bin/env bash
# Fase 2 - Bloque 3a: VM de la Intranet de RR. HH. (sin IP publica, en la subred del Data Center).
# nginx y la pagina se configuran a mano DENTRO de la VM (ver GUIA_Bloque3.md).
set -euo pipefail
source "$(dirname "$0")/config.env"
gcloud config set project "$PROJECT_ID"

echo ">> Creando qr-vm-intranet (${IP_INTRANET}) con tags dc,intranet y SIN IP publica"
gcloud compute instances create qr-vm-intranet \
  --zone="$ZONE" --machine-type="$MACHINE_TYPE" \
  --subnet=qr-snet-dc --private-network-ip="$IP_INTRANET" --no-address \
  --tags=dc,intranet --labels="proyecto=redes-fase2,segmento=dc,rol=intranet" \
  --image-family="$IMAGE_FAMILY" --image-project="$IMAGE_PROJECT" \
  --boot-disk-size=10GB --boot-disk-type=pd-standard \
  --shielded-secure-boot

echo ">> Listo:"
gcloud compute instances list --filter="name=qr-vm-intranet" \
  --format="table(name,zone.basename(),networkInterfaces[0].networkIP:label=IP_INTERNA,networkInterfaces[0].accessConfigs[0].natIP:label=IP_EXTERNA,tags.items.list():label=TAGS,status)"
