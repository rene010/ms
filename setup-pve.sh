#!/bin/bash
# lave script filen init-script.sh og den ligger i /usr/local/bin og lig kode inde i filen
cat << 'EOF' > /usr/local/bin/init-script.sh
#!/bin/bash
# Script til at opdatere hostname, IP-adresse, gateway, SEARCH domain og DNS server
# pve update certs og genstarte SSH-tjenesten
# Slette gamle SSH host nogler
# Maskine ID opsaetning
# Flyt scriptet til en anden mappe

# Sporg efter hostname
read -r -p "Indtast det nye hostname: " NEW_HOSTNAME
read -r -p "Indtast FQDN (format: hostname.domain): " FQDN

# Sporg efter IP-adresse
read -r -p "Indtast den nye IP-adresse (format: xxx.xxx.xxx.xxx/xx): " NEW_IP
read -r -p "Indtast gateway (format: xxx.xxx.xxx.xxx): " GATEWAY
read -r -p "Indtast SEARCH domain (format: xxxxx): " SEARCH
read -r -p "Indtast DNS server (format: xxx.xxx.xxx.xxx): " DNS_SERVER

# Opdater /etc/hostname
hostnamectl hostname "$NEW_HOSTNAME"

# Opdater /etc/hosts
sed -i "2s/.*/${NEW_IP%/*} $FQDN $NEW_HOSTNAME/" /etc/hosts
# Opdater netvaerksindstillinger i /etc/network/interfaces
sed -i "s#^\s*address .*# address $NEW_IP#" /etc/network/interfaces
sed -i "s#^\s*gateway .*# gateway $GATEWAY#" /etc/network/interfaces
# Append or replace the search line
grep -q "^search" /etc/resolv.conf && sed -i "s/^search.*/search $SEARCH/" /etc/resolv.conf || echo "search $SEARCH" >>/etc/resolv.conf
# Append or replace the nameserver line
grep -q "^nameserver" /etc/resolv.conf && sed -i "s/^nameserver.*/nameserver $DNS_SERVER/" /etc/resolv.conf || echo "nameserver $DNS_SERVER" >>/etc/resolv.conf

# Genstart netvaerkstjenesten
systemctl restart networking
ifreload -a

# pve update certs
pvecm updatecerts --force
systemctl restart pveproxy

# Slet gamle SSH host nogler
rm -v /etc/ssh/ssh_host_*
# Rekonfigurer OpenSSH-serveren
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure openssh-server
# Sørg for at SSH-tjenesten kører korrekt
/lib/systemd/systemd-sysv-install enable ssh
systemctl restart ssh.service

# Maskine ID opsaetning
rm /etc/machine-id
truncate -s 0 /etc/machine-id
rm /var/lib/dbus/machine-id
systemd-machine-id-setup
ln -sf /etc/machine-id /var/lib/dbus/machine-id

# Flyt scriptet til en anden mappe
SCRIPT_NAME=init-script.sh.done
mkdir -p /temp/
mv "/etc/profile.d/init-script.sh" "/temp/$SCRIPT_NAME"

# Bekræft genstart
read -r -p "Vil du genstarte systemet nu? (y/n): " CONFIRM_REBOOT
if [ "$CONFIRM_REBOOT" = "y" ]; then
    reboot
else
    echo "Genstart ikke."
fi
EOF
chmod +x /usr/local/bin/init-script.sh

# lave script filen init-script.sh og den ligger i /etc/profile.d
cat << 'EOF' > /etc/profile.d/init-script.sh
#!/bin/bash

# Kontroller, om init-scriptet allerede er kørt
if [ ! -f /tmp/init-done ]; then
    # Kør init-scriptet, hvis det ikke er kørt før
    echo "Running init-script.sh"
    source /usr/local/bin/init-script.sh
    # Marker, at init-scriptet er kørt
    touch /tmp/init-done
else
    # Vis besked, hvis init-scriptet allerede er kørt
    echo "init-script.sh has already been run"
fi
EOF
chmod +x /etc/profile.d/init-script.sh




