#!/usr/bin/env bash
# Fase 2 - Bloque 1a: subred DMZ, IP publica estatica y Cloud Router + Cloud NAT.
set -euo pipefail
source "$(dirname "$0")/config.env"
gcloud config set project "$PROJECT_ID"

echo ">> Subred DMZ (bloque libre reservado en la Fase 1)"
gcloud compute networks subnets create qr-snet-dmz --network="$VPC" --region="$REGION" \
  --range="$CIDR_DMZ" --description="DMZ: servidores publicos (web de Ventas)"

echo ">> IP publica estatica para la web de la DMZ (ya reservada si existe)"
gcloud compute addresses describe qr-ip-web-dmz --region="$REGION" >/dev/null 2>&1 || \
  gcloud compute addresses create qr-ip-web-dmz --region="$REGION" \
    --description="IP publica del servidor web de la DMZ (Ventas)"

echo ">> Cloud Router (necesario para Cloud NAT)"
gcloud compute routers create qr-router --network="$VPC" --region="$REGION" \
  --description="Router regional para Cloud NAT"

echo ">> Cloud NAT: salida a Internet sin IP publica para las subredes internas"
# La DMZ no se incluye: su servidor tiene IP publica propia.
gcloud compute routers nats create qr-router-nat --router=qr-router --region="$REGION" \
  --auto-allocate-nat-external-ips \
  --nat-custom-subnet-ip-ranges=qr-snet-ventas,qr-snet-visitas,qr-snet-ti,qr-snet-dc \
  --enable-logging --log-filter=ERRORS_ONLY

echo ">> Listo. Resumen:"
gcloud compute networks subnets list --network="$VPC"
gcloud compute addresses list
gcloud compute routers nats describe qr-router-nat --router=qr-router --region="$REGION"
