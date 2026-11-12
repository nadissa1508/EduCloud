#!/usr/bin/env bash
# Fase 2 - Bloque 6: matriz de pruebas final (despues del hardening). Requiere las 7 VMs encendidas.
# Cada prueba entra a la VM indicada por IAP, ejecuta el comando y muestra el resultado junto al esperado.
# Salida: resultados_fase2.txt
set -uo pipefail
source "$(dirname "$0")/config.env"
gcloud config set project "$PROJECT_ID" >/dev/null 2>&1
SALIDA="$(dirname "$0")/resultados_fase2.txt"
DOMINIO="$DOMINIO_PUBLICO"
N=0

prueba () {  # descripcion  vm|cloudshell  comando  esperado
  N=$((N+1))
  echo
  echo "=== Prueba $N: $1"
  echo "    Desde: $2   |   Esperado: $4"
  echo "    \$ $3"
  if [ "$2" = "cloudshell" ]; then
    bash -c "$3" 2>&1 | sed 's/^/    /'
  else
    gcloud compute ssh "$2" --zone="$ZONE" --tunnel-through-iap --quiet --command="$3" 2>/dev/null | sed 's/^/    /'
  fi
}

PING='ping -c 3 -W 2'
CODIGO='curl -s -o /dev/null -m 5 -w "HTTP %{http_code}\n"'

{
echo "EduCloud - Fase 2 - Matriz de pruebas final"
echo "Fecha: $(date -u '+%Y-%m-%d %H:%M UTC')   Proyecto: $PROJECT_ID"

echo; echo "################ DNS interno ################"
prueba "Ventas resuelve la intranet por DNS interno" qr-vm-ventas-01 "dig +short rrhh.${ZONA_INTERNA}" "10.20.0.163"
prueba "Alias CNAME de la intranet" qr-vm-ventas-01 "dig +short intranet.${ZONA_INTERNA}" "rrhh.${ZONA_INTERNA}. + 10.20.0.163"
prueba "BIND no hace recursion (hardening)" qr-vm-dc-01 "dig @127.0.0.1 www.google.com | grep status" "status: REFUSED"

echo; echo "################ Intranet RR. HH. ################"
prueba "Ventas accede a la intranet" qr-vm-ventas-01 "$CODIGO http://rrhh.${ZONA_INTERNA}" "HTTP 200"
prueba "TI accede a la intranet" qr-vm-ti-01 "$CODIGO http://rrhh.${ZONA_INTERNA}" "HTTP 200"
prueba "Visitas NO accede a la intranet" qr-vm-visitas-01 "$CODIGO http://rrhh.${ZONA_INTERNA}" "HTTP 000 (timeout)"

echo; echo "################ Visitas ################"
prueba "Visitas tiene Internet (Cloud NAT)" qr-vm-visitas-01 "$CODIGO https://www.google.com" "HTTP 200"
prueba "Visitas NO llega a Ventas" qr-vm-visitas-01 "$PING 10.20.0.10 | grep loss" "100% packet loss"

echo; echo "################ TI ################"
prueba "Ventas NO llega a TI" qr-vm-ventas-01 "$PING 10.20.0.130 | grep loss" "100% packet loss"
prueba "DC NO llega a TI" qr-vm-dc-01 "$PING 10.20.0.130 | grep loss" "100% packet loss"
prueba "TI llega a Ventas" qr-vm-ti-01 "$PING 10.20.0.10 | grep loss" "0% packet loss"
prueba "TI llega a Visitas" qr-vm-ti-01 "$PING 10.20.0.70 | grep loss" "0% packet loss"
prueba "TI llega a Data Center" qr-vm-ti-01 "$PING 10.20.0.162 | grep loss" "0% packet loss"
prueba "TI llega a la DMZ" qr-vm-ti-01 "$PING 10.20.0.178 | grep loss" "0% packet loss"

echo; echo "################ DMZ y web publica ################"
prueba "HTTP redirige a HTTPS" cloudshell "curl -sI http://${DOMINIO} | grep -Ei '^(HTTP|location)'" "301 + Location: https://..."
prueba "HTTPS con certificado valido" cloudshell "curl -sI https://${DOMINIO} | grep -Ei '^(HTTP|server|strict)'" "HTTP/2 200, server: nginx sin version, HSTS"
prueba "Emisor del certificado" cloudshell "echo | openssl s_client -connect ${DOMINIO}:443 -servername ${DOMINIO} 2>/dev/null | openssl x509 -noout -issuer -enddate" "Let's Encrypt + fecha de vencimiento"
prueba "DMZ NO llega a la intranet" qr-vm-web-dmz "$CODIGO http://10.20.0.163" "HTTP 000 (timeout)"
prueba "DMZ NO llega al DNS interno" qr-vm-web-dmz "$PING 10.20.0.162 | grep loss" "100% packet loss"

echo; echo "################ Hardening ################"
prueba "UFW activo en la web publica" qr-vm-web-dmz "sudo ufw status | head -1" "Status: active"
prueba "SSH sin root ni contrasenas" qr-vm-intranet "sudo sshd -T | grep -E '^(permitrootlogin|passwordauthentication) '" "no / no"
prueba "Solo la DMZ tiene IP publica" cloudshell "gcloud compute instances list --format='table(name,networkInterfaces[0].accessConfigs[0].natIP:label=IP_PUBLICA)'" "Solo qr-vm-web-dmz con 35.255.179.44"

echo; echo "Total de pruebas: $N"
} | tee "$SALIDA"

echo; echo ">> Resultados guardados en $SALIDA"
