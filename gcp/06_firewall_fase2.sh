#!/usr/bin/env bash
# Fase 2 - Bloque 1b: reestructura del firewall (hardening) y reglas nuevas.
set -euo pipefail
source "$(dirname "$0")/config.env"
gcloud config set project "$PROJECT_ID"

CLOUD_DNS_RANGE="35.199.192.0/19"   # origen de las consultas reenviadas por Cloud DNS

echo ">> Hardening: reglas intra-subred solo con ICMP (antes: todos los puertos tcp/udp)"
gcloud compute firewall-rules update qr-fw-ventas-intra --rules=icmp
gcloud compute firewall-rules update qr-fw-ti-intra     --rules=icmp
gcloud compute firewall-rules update qr-fw-dc-intra     --rules=icmp

echo ">> TI administra todo, incluida la DMZ; se quita RDP (3389) porque todo es Linux"
gcloud compute firewall-rules update qr-fw-ti-admin \
  --rules=icmp,tcp:22,tcp:53,udp:53,tcp:80,tcp:443 \
  --target-tags=ventas,dc,visitas,dmz \
  --description="TI administra todas las subredes (SSH, DNS, web)"

echo ">> Logging en el bloqueo de Visitas (evidencia de paquetes denegados)"
gcloud compute firewall-rules update qr-fw-visitas-deny-privadas --enable-logging

echo ">> Reglas nuevas"
gcloud compute firewall-rules create qr-fw-dns-interno --network="$VPC" \
  --direction=INGRESS --priority=1000 --action=ALLOW --rules=udp:53,tcp:53 \
  --source-ranges="$CLOUD_DNS_RANGE,$CIDR_VENTAS,$CIDR_TI,$CIDR_DC" --target-tags=dns \
  --description="Consultas DNS a BIND (reenvio de Cloud DNS y subredes internas)"

gcloud compute firewall-rules create qr-fw-intranet-http --network="$VPC" \
  --direction=INGRESS --priority=1000 --action=ALLOW --rules=tcp:80 \
  --source-ranges="$CIDR_VENTAS,$CIDR_TI,$CIDR_DC" --target-tags=intranet \
  --description="Intranet RR.HH. solo para subredes de empleados (no Visitas, no Internet)"

gcloud compute firewall-rules create qr-fw-dmz-web-publica --network="$VPC" \
  --direction=INGRESS --priority=1000 --action=ALLOW --rules=tcp:80,tcp:443 \
  --source-ranges=0.0.0.0/0 --target-tags=web-publica \
  --description="Web publica de Ventas accesible desde Internet (HTTP->HTTPS)"

gcloud compute firewall-rules create qr-fw-dmz-deny-internas --network="$VPC" \
  --direction=EGRESS --priority=900 --action=DENY --rules=all \
  --destination-ranges=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16 --target-tags=dmz \
  --enable-logging \
  --description="La DMZ no puede iniciar conexiones hacia la red interna"

gcloud compute firewall-rules create qr-fw-ti-deny-resto --network="$VPC" \
  --direction=INGRESS --priority=2000 --action=DENY --rules=all \
  --source-ranges=10.20.0.0/24 --target-tags=ti --enable-logging \
  --description="Nadie fuera de TI llega a TI (explicito para registrar los intentos)"

echo ">> Listo. Reglas actuales:"
gcloud compute firewall-rules list --filter="network:$VPC" \
  --format="table(name,direction,priority,sourceRanges.list():label=ORIGEN,destinationRanges.list():label=DESTINO,allowed[].map().firewall_rule().list():label=PERMITE,denied[].map().firewall_rule().list():label=DENIEGA,targetTags.list():label=TAGS,logConfig.enable:label=LOG)"
