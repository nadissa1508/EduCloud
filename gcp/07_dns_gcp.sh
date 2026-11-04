#!/usr/bin/env bash
# Fase 2 - Bloque 2a: lado GCP del DNS interno (etiqueta dns + zona de reenvio en Cloud DNS).
# La configuracion de BIND9 se hace a mano DENTRO de qr-vm-dc-01 (ver GUIA_Bloque2.md).
set -euo pipefail
source "$(dirname "$0")/config.env"
gcloud config set project "$PROJECT_ID"

echo ">> Etiqueta 'dns' en qr-vm-dc-01 (activa la regla qr-fw-dns-interno sobre esta VM)"
gcloud compute instances add-tags qr-vm-dc-01 --zone="$ZONE" --tags=dns

echo ">> Habilitando la API de Cloud DNS"
gcloud services enable dns.googleapis.com

echo ">> Zona privada de REENVIO: las consultas *.${ZONA_INTERNA} se envian a BIND (${IP_DC_01})"
gcloud dns managed-zones create qr-zona-educloud-local \
  --dns-name="${ZONA_INTERNA}." \
  --visibility=private --networks="$VPC" \
  --forwarding-targets="$IP_DC_01" \
  --description="Reenvia ${ZONA_INTERNA} al servidor BIND interno (qr-vm-dc-01)"

echo ">> Listo. Resumen:"
gcloud compute instances describe qr-vm-dc-01 --zone="$ZONE" --format="value(name,tags.items)"
gcloud dns managed-zones describe qr-zona-educloud-local \
  --format="table(name,dnsName,visibility,forwardingConfig.targetNameServers[].ipv4Address.list():label=REENVIA_A)"
