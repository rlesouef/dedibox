#!/bin/bash
# Installation LXC
# Virtualisation
# Open Source Services - 01/2015
# GPL
#
# Syntaxe: # su - -c "./lxc-init.sh"
# Syntaxe: or # sudo ./lxc-init.sh
# 

# Doit etre lance en root
if [ $EUID -ne 0 ]; then
  echo "Le script doit être lancé en root: # sudo $0" 1>&2
  exit 1
fi

# Fonctions
#-----------------------------------
sauveFic() {
  if [ ! -f ${1} ]; then
      echo "ERREUR: $1 inexistant!!!"
    fi
  if [ ! -f ${1}.0 ]; then
      cp ${1} ${1}.0
      echo "$1 sauvegardé"
  else
    cp ${1}.0 ${1}
    echo "$1 restauré"
  fi
}

pose() {
  echo -n "<ENTREE> pour continuer ou <CTRL+C> pour arreter"
  read a
}

# Traitement
#-----------------------------------
clear

echo -e "\n-- Traitement"
echo "  > installation de LXC"
echo "  > Creation de 4 conteneurs"
echo "      - proxy [10.0.3.100]"
echo "      - web   [10.0.3.101]"
echo "      - odoo  [10.0.3.102]"
echo "      - perso [10.0.3.103]"

pose

# LXC
echo -e "\n--- Installation Lxc"
sauveFic '/etc/fstab'
echo 'cgroup /sys/fs/cgroup cgroup defaults 0 0' >> /etc/fstab
mount /sys/fs/cgroup
apt-get update
/usr/bin/apt-get remove -y --force-yes --purge lxc bridge-utils
/usr/bin/apt-get -y --force-yes install lxc bridge-utils
lxc-checkconfig

pose

sauveFic '/etc/default/lxc-net'
sed -i 's/LXC_ADDR="10.0.3.1"/LXC_ADDR="10.0.3.254"/g' /etc/default/lxc-net
sed -i 's/#LXC_DHCP_CONFILE=/LXC_DHCP_CONFILE=/g' /etc/default/lxc-net
sauveFic '/etc/lxc/dnsmasq.conf'
cat <<EOF >/etc/lxc/dnsmasq.conf
dhcp-host=srv-dns,10.0.3.100
dhcp-host=srv-proxy,10.0.3.101
dhcp-host=srv-mail,10.0.3.102
dhcp-host=web,10.0.3.110
dhcp-host=perso,10.0.3.120
dhcp-host=odoo,10.0.3.130
EOF

service lxc-net restart

lxc-create -t ubuntu -n srv-dns
lxc-create -t ubuntu -n srv-proxy
lxc-create -t ubuntu -n srv-mail
lxc-create -t ubuntu -n web
lxc-create -t ubuntu -n perso
lxc-create -t ubuntu -n odoo

cat <<EOF >>/var/lib/lxc/srv-dns/config

lxc.start.auto = 1
lxc.start.order = 1
lxc.start.delay = 0
EOF

cat <<EOF >>/var/lib/lxc/srv-proxy/config

lxc.start.auto = 1
lxc.start.order = 2
lxc.start.delay = 1
EOF

cat <<EOF >>/var/lib/lxc/srv-mail/config

lxc.start.auto = 1
lxc.start.order = 3
lxc.start.delay = 1
EOF

cat <<EOF >>/var/lib/lxc/web/config

lxc.start.auto = 1
lxc.start.order = 4
lxc.start.delay = 2
EOF

cat <<EOF >>/var/lib/lxc/perso/config

lxc.start.auto = 1
lxc.start.order = 5
lxc.start.delay = 2
EOF

cat <<EOF >>/var/lib/lxc/odoo/config

lxc.start.auto = 1
lxc.start.order = 6
lxc.start.delay = 2
EOF

lxc-start -d -n srv-dns
lxc-start -d -n srv-proxy
lxc-start -d -n srv-mail
lxc-start -d -n web
lxc-start -d -n perso
lxc-start -d -n odoo

Lxc-ls --fancy

echo "Pour chaque conteneur:"
echo "---------------------------"
echo "lxc-console -n nomConteneur"
echo "ubuntu / ubuntu"
echo "sudo su"
echo "adduser nomUser"
echo "usermod -a -G sudo nomUser"
echo "exit ou [CTRL+D]"
echo "exit ou [CTRL+D]"
echo "login: nomUser / pwdUser"
echo "sudo su"
echo "deluser ubuntu --remove-home"
echo "apt-get update"
echo "apt-get dist-upgrade"
echo "apt-get install nano wget git iptables aptitude"
echo "..."
echo "[CTRL+A] puis [Q] pour quitter lxc-console et revenir sur le host"

echo "Demarrage automatique"
echo "nano /var/lib/lxc/nomConteneur/config"
echo "lxc.start.auto = 1"
echo "lxc.start.order = x"
echo "lxc.start.delay = x"

exit 0
