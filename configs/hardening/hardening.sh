#!/usr/bin/env bash
# Hardening de host para las VMs de EduCloud. Se ejecuta DENTRO de cada VM:
#   sudo bash hardening.sh <rol>
# Roles: cliente (ventas, ti, visitas) | dns (dc-01) | intranet | web (DMZ)
set -euo pipefail
ROL="${1:?Uso: sudo bash hardening.sh cliente|dns|intranet|web}"

IAP="35.235.240.0/20"        # Identity-Aware Proxy (SSH administrativo)
TI="10.20.0.128/27"
VENTAS="10.20.0.0/26"
DC="10.20.0.160/28"
CLOUD_DNS="35.199.192.0/19"  # reenviadores de Cloud DNS

echo ">> [1/4] Firewall de host (UFW): denegar todo lo entrante y abrir solo lo del rol '$ROL'"
command -v ufw >/dev/null || { apt-get update -qq; DEBIAN_FRONTEND=noninteractive apt-get install -y -qq ufw; }
ufw --force reset >/dev/null
ufw default deny incoming
ufw default allow outgoing
ufw allow from "$IAP" to any port 22 proto tcp comment 'SSH via IAP'
ufw allow from "$TI"  to any port 22 proto tcp comment 'SSH desde TI'
case "$ROL" in
  cliente)  ;;
  dns)      for r in "$VENTAS" "$TI" "$DC" "$CLOUD_DNS"; do ufw allow from "$r" to any port 53 comment 'DNS'; done ;;
  intranet) for r in "$VENTAS" "$TI" "$DC"; do ufw allow from "$r" to any port 80 proto tcp comment 'Intranet HTTP'; done ;;
  web)      ufw allow 80/tcp comment 'HTTP (redirige a HTTPS)'; ufw allow 443/tcp comment 'HTTPS' ;;
  *)        echo "Rol desconocido: $ROL"; exit 1 ;;
esac
ufw logging low
ufw --force enable
ufw status verbose

echo ">> [2/4] SSH: sin root, sin contrasenas, solo llaves"
cat > /etc/ssh/sshd_config.d/01-educloud-hardening.conf <<'EOF'
# Hardening EduCloud (se lee antes que los demas archivos: en sshd gana el primer valor)
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
X11Forwarding no
MaxAuthTries 3
LoginGraceTime 30
EOF
sshd -t && systemctl reload ssh
sshd -T | grep -Ei '^(permitrootlogin|passwordauthentication|kbdinteractiveauthentication|x11forwarding|maxauthtries|logingracetime) '

echo ">> [3/4] Servicios innecesarios: LLMNR (5355) de systemd-resolved y servidor de correo exim4"
mkdir -p /etc/systemd/resolved.conf.d
printf '[Resolve]\nLLMNR=no\nMulticastDNS=no\n' > /etc/systemd/resolved.conf.d/01-educloud-hardening.conf
systemctl restart systemd-resolved
if systemctl list-unit-files exim4.service >/dev/null 2>&1; then systemctl disable --now exim4 || true; fi

echo ">> [3b] Actualizaciones de seguridad automaticas"
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq unattended-upgrades >/dev/null
systemctl is-enabled unattended-upgrades

echo ">> [4/4] Puertos que quedan escuchando"
ss -tulpn | grep -v '127.0.0.1\|\[::1\]\|127.0.0.53' || true
echo ">> Hardening '$ROL' aplicado en $(hostname)"
