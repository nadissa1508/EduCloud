#!/usr/bin/env bash
# Crea la VPC, las 4 subredes y las reglas de firewall de EduCloud Guatemala.
set -euo pipefail
source "$(dirname "$0")/config.env"
gcloud config set project "$PROJECT_ID"

echo ">> Habilitando APIs (Compute Engine e IAP)"
gcloud services enable compute.googleapis.com iap.googleapis.com

echo ">> VPC en modo personalizado (sin subredes automaticas)"
gcloud compute networks create "$VPC" \
  --subnet-mode=custom --bgp-routing-mode=regional \
  --description="Red corporativa EduCloud Guatemala"

echo ">> Subredes (VLSM sobre 10.20.0.0/24)"
gcloud compute networks subnets create qr-snet-ventas  --network="$VPC" --region="$REGION" --range="$CIDR_VENTAS"  --enable-private-ip-google-access --description="Ventas (25 usuarios)"
gcloud compute networks subnets create qr-snet-visitas --network="$VPC" --region="$REGION" --range="$CIDR_VISITAS" --description="Visitas (aislada)"
gcloud compute networks subnets create qr-snet-ti      --network="$VPC" --region="$REGION" --range="$CIDR_TI"      --enable-private-ip-google-access --description="TI (15 usuarios)"
gcloud compute networks subnets create qr-snet-dc      --network="$VPC" --region="$REGION" --range="$CIDR_DC"      --enable-private-ip-google-access --description="Data Center (5 servidores)"

echo ">> Reglas de firewall"
# GCP aplica por defecto: ingreso denegado y egreso permitido. Solo abrimos lo necesario.
gcloud compute firewall-rules create qr-fw-allow-iap-ssh --network="$VPC" \
  --direction=INGRESS --priority=1000 --action=ALLOW --rules=tcp:22 \
  --source-ranges="$IAP_RANGE" --description="SSH administrativo solo via IAP"

gcloud compute firewall-rules create qr-fw-ventas-intra --network="$VPC" \
  --direction=INGRESS --priority=1000 --action=ALLOW --rules=icmp,tcp,udp \
  --source-ranges="$CIDR_VENTAS" --target-tags=ventas --description="Trafico dentro de Ventas"

gcloud compute firewall-rules create qr-fw-ti-intra --network="$VPC" \
  --direction=INGRESS --priority=1000 --action=ALLOW --rules=icmp,tcp,udp \
  --source-ranges="$CIDR_TI" --target-tags=ti --description="Trafico dentro de TI"

gcloud compute firewall-rules create qr-fw-dc-intra --network="$VPC" \
  --direction=INGRESS --priority=1000 --action=ALLOW --rules=icmp,tcp,udp \
  --source-ranges="$CIDR_DC" --target-tags=dc --description="Trafico entre servidores"

gcloud compute firewall-rules create qr-fw-ti-admin --network="$VPC" \
  --direction=INGRESS --priority=1000 --action=ALLOW --rules=icmp,tcp:22,tcp:3389 \
  --source-ranges="$CIDR_TI" --target-tags=ventas,dc,visitas --description="TI administra todas las subredes"

gcloud compute firewall-rules create qr-fw-ventas-a-dc --network="$VPC" \
  --direction=INGRESS --priority=1000 --action=ALLOW --rules=icmp,tcp:80,tcp:443 \
  --source-ranges="$CIDR_VENTAS" --target-tags=dc --description="Ventas consume apps web del DC"

gcloud compute firewall-rules create qr-fw-visitas-deny-privadas --network="$VPC" \
  --direction=EGRESS --priority=900 --action=DENY --rules=all \
  --destination-ranges=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16 --target-tags=visitas \
  --description="Visitas no puede alcanzar ninguna red privada (solo Internet)"

echo ">> Listo. Resumen:"
gcloud compute networks subnets list --network="$VPC"
gcloud compute firewall-rules list --filter="network:$VPC"
