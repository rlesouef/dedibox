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
/usr/bin/apt-get remove -y --force-yes --purge lxc
/usr/bin/apt-get -y --force-yes install lxc
sauveFic '/etc/default/lxc-net'
sed -i 's/LXC_ADDR="10.0.3.1"/LXC_ADDR="10.0.3.254"/g' /etc/default/lxc-net
sed -i 's/#LXC_DHCP_CONFILE=/LXC_DHCP_CONFILE=/g' /etc/default/lxc-net
sauveFic '/etc/lxc/dnsmasq.conf'
cat <<EOF >/etc/lxc/dnsmasq.conf
dhcp-host=proxy,10.0.3.100
dhcp-host=web,10.0.3.101
dhcp-host=odoo,10.0.3.102
dhcp-host=perso,10.0.3.103
EOF
service lxc-net restart

# Conteneur 'proxy'
echo -e "\n--- Création du conteneur 'proxy'"
lxc-create -t ubuntu -n proxy
lxc-start -d -n proxy

# Conteneur 'web'
echo -e "\n--- Création du conteneur 'web'"
lxc-create -t ubuntu -n web
lxc-start -d -n web

# Conteneur 'odoo'
echo -e "\n--- Création du conteneur 'odoo'"
lxc-create -t ubuntu -n odoo
lxc-start -d -n odoo

# Conteneur 'perso'
echo -e "\n--- Création du conteneur 'perso'"
lxc-create -t ubuntu -n perso
lxc-start -d -n perso

Lxc-ls --fancy

exit 0
