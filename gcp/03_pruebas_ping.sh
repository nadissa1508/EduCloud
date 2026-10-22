#!/usr/bin/env bash
# Ejecuta la matriz de pruebas de conectividad (ping) via SSH por IAP.
# Guarda la salida completa en resultados_ping.txt para anexarla al reporte.
set -uo pipefail
source "$(dirname "$0")/config.env"
gcloud config set project "$PROJECT_ID" >/dev/null
OUT="$(dirname "$0")/resultados_ping.txt"
: > "$OUT"

probar () {  # origen destino_ip descripcion esperado
  echo "==================================================================" | tee -a "$OUT"
  echo "PRUEBA: $3 | $1 -> $2 | Esperado: $4" | tee -a "$OUT"
  echo "==================================================================" | tee -a "$OUT"
  gcloud compute ssh "$1" --zone="$ZONE" --tunnel-through-iap --quiet \
    --command="hostname; ip -4 -br addr show ens4; ping -c 4 -W 2 $2" 2>&1 | tee -a "$OUT"
  echo "" | tee -a "$OUT"
}

probar qr-vm-ventas-01  "$IP_VENTAS_02" "Ventas a Ventas (misma subred)"    "EXITO"
probar qr-vm-ventas-02  "$IP_VENTAS_01" "Ventas a Ventas (sentido inverso)" "EXITO"
probar qr-vm-ti-01      "$IP_DC_01"     "TI a Data Center"                  "EXITO"
probar qr-vm-ti-01      "$IP_VENTAS_01" "TI a Ventas (administracion)"      "EXITO"
probar qr-vm-ventas-01  "$IP_DC_01"     "Ventas a Data Center"              "EXITO"
probar qr-vm-ventas-01  "$IP_TI_01"     "Ventas a TI"                       "FALLA (100% loss)"
probar qr-vm-visitas-01 "$IP_VENTAS_01" "Visitas a Ventas"                  "FALLA (100% loss)"
probar qr-vm-visitas-01 "$IP_DC_01"     "Visitas a Data Center"             "FALLA (100% loss)"

echo "Resultados guardados en $OUT"
