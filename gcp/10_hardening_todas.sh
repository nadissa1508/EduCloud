#!/usr/bin/env bash
# Fase 2 - Bloque 5b: aplica configs/hardening/hardening.sh en las VMs restantes (dc-01 se hace a mano).
# Requiere las VMs encendidas.
set -euo pipefail
source "$(dirname "$0")/config.env"
gcloud config set project "$PROJECT_ID"
HARDENING="$(dirname "$0")/../configs/hardening/hardening.sh"

declare -A ROLES=(
  [qr-vm-ventas-01]=cliente
  [qr-vm-ventas-02]=cliente
  [qr-vm-ti-01]=cliente
  [qr-vm-visitas-01]=cliente
  [qr-vm-intranet]=intranet
  [qr-vm-web-dmz]=web
)

for vm in qr-vm-ventas-01 qr-vm-ventas-02 qr-vm-ti-01 qr-vm-visitas-01 qr-vm-intranet qr-vm-web-dmz; do
  echo; echo "==================== $vm (rol: ${ROLES[$vm]}) ===================="
  gcloud compute scp "$HARDENING" "$vm":~ --zone="$ZONE" --tunnel-through-iap --quiet
  gcloud compute ssh "$vm" --zone="$ZONE" --tunnel-through-iap --quiet \
    --command="sudo bash ~/hardening.sh ${ROLES[$vm]}"
done
