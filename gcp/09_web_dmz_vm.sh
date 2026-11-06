#!/usr/bin/env bash
# Fase 2 - Bloque 4a: VM del servidor web publico de Ventas en la DMZ, con la IP publica estatica reservada.
# nginx y el certificado TLS se configuran a mano DENTRO de la VM (ver GUIA_Bloque4.md).
set -euo pipefail
source "$(dirname "$0")/config.env"
gcloud config set project "$PROJECT_ID"

echo ">> Creando qr-vm-web-dmz (${IP_WEB_DMZ}) con IP publica ${IP_PUBLICA_WEB} y tags dmz,web-publica"
gcloud compute instances create qr-vm-web-dmz \
  --zone="$ZONE" --machine-type="$MACHINE_TYPE" \
  --subnet=qr-snet-dmz --private-network-ip="$IP_WEB_DMZ" --address="$IP_PUBLICA_WEB" \
  --tags=dmz,web-publica --labels="proyecto=redes-fase2,segmento=dmz,rol=web-publica" \
  --image-family="$IMAGE_FAMILY" --image-project="$IMAGE_PROJECT" \
  --boot-disk-size=10GB --boot-disk-type=pd-standard \
  --shielded-secure-boot

echo ">> Listo:"
gcloud compute instances list --filter="name=qr-vm-web-dmz" \
  --format="table(name,zone.basename(),networkInterfaces[0].networkIP:label=IP_INTERNA,networkInterfaces[0].accessConfigs[0].natIP:label=IP_EXTERNA,tags.items.list():label=TAGS,status)"
gcloud compute addresses describe qr-ip-web-dmz --region="$REGION" --format="table(name,address,status,users.list().basename():label=EN_USO_POR)"
