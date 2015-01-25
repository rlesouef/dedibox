#!/bin/bash
# Mon script de post installation dedibox
#
# Nicolargo - 12/2011
# GPL
#
# Syntaxe: # su - -c "./dediboxpostinstall.sh"
# Syntaxe: or # sudo ./dediboxpostinstall.sh
# 

# Fonctions
#-----------------------------------
sauve_fic() {
  if [ ! -f ${1} ]; then
      echo "ERREUR: $1 inexistant!!!"
      exit 1
    fi
  if [ ! -f ${1}.0 ]; then
      cp ${1} ${1}.0
      echo "$1 sauvegardé"
  else
    cp ${1}.0 ${1}
    echo "$1 restauré"
  fi
}

continuer() {
  echo -n "Souhaitez-vous continuer ? [O/n] "
  read suite
  if [ "$suite" = "n" ] || [ "$suite" = "N" ]; then
    exit 1
  fi
}

# Variables
#-----------------------------------
VERSION="1.00"
# utilisateur
USER_NAME="myName"
# Adresse mail pour les rapports de securite
ADR_MAIL="root@localhost"
# port SSH
PORT_SSH="22"
# Adresse IP Publique
ADR_IPPUB="1.2.3.4"
# Adresse Mac Publique
ADR_MACPUB="xx:yy:zz:ff:bb:cc"
# Adresse IP Failover
ADR_IPFO="10.20.30.40"
# Adresse Mac Failover
ADR_MACFO=""

# le script doit etre lance en root
if [ $EUID -ne 0 ]; then
  echo "Le script doit être lancé en root: # sudo $0" 1>&2
  exit 1
fi

clear
echo "Pour utiliser les réponses par défaut à toutes les questions lors de l'installation des paquets"
echo "Debconf doit etre positionne sur [Non interactive] et [eleve]"
echo "Pour le positionner, quitter le script et taper :"
echo -e "\tdpkg-reconfigure debconf"

continuer

# Affichage des parametres
#-----------------------------------
echo "#============================================================================="
echo "# Saisie des parametres:"
echo "#============================================================================="

echo -n "Nom utilisateur : "
read USER_NAME
echo -n "Adresse mail pour les rapports de securite : "
read ADR_MAIL
echo -n "Port SSH : "
read PORT_SSH
echo -n "Adresse IP Publique : "
read ADR_IPPUB
echo -n "Adresse Mac Publique : "
read ADR_MACPUB
echo -n "Adresse IP Failover : "
read ADR_IPFO
echo -n "Adresse Mac Failover : "
read ADR_MACFO


echo -e "\n#============================================================================="
echo "# Utilisateur: $USER_NAME"
echo "# Adresse mail pour les rapports de securite: $ADR_MAIL"
echo "# Port SSH: $PORT_SSH"
echo "# Adresse IP Publique: $ADR_IPPUB"
echo "# Adresse Mac Publique: $ADR_MACPUB"
echo "# Adresse IP Failover: $ADR_IPFO"
echo "# Adresse Mac Failover: $ADR_MACFO"
echo "#============================================================================="
echo " "

continuer

# Update 
echo -e "\nMise a jour de la liste des depots"
/usr/bin/apt-get update

# Upgrade
echo -e "\nMise a jour du systeme"
/usr/bin/apt-get -y dist-upgrade

# Mise a jour des locales
echo -e "\nMise a jour des locales"
locale-gen fr_FR.UTF-8
update-locale LANG=fr_FR.UTF-8

# Installation de paquets
echo -e "\n--- Installation paquets"
/usr/bin/apt-get -y --force-yes install git

# SSH
echo -e "\n--- SSH"
# /usr/bin/apt-get -y --force-yes install openssh-server
sauve_fic '/etc/ssh/sshd_config'
sed -i 's/Port 22/Port '$PORT_SSH'/g' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin without-password/PermitRootLogin no/g' /etc/ssh/sshd_config
sed -i 's/X11Forwarding yes/X11Forwarding no/g' /etc/ssh/sshd_config
echo "AllowUsers $USER_NAME" >> /etc/ssh/sshd_config
service ssh restart

continuer

# firewall
echo -e "\n--- Firewall"
git clone https://github.com/rlesouef/dedibox ~/dedibox
sed -i 's/PORT="22"/Port="'$PORT_SSH'"/g' ~/dedibox/firewall.sh
sed -i 's/HN_IP="1.2.3.4"/HN_IP="'$ADR_IPPUB'"/g' ~/dedibox/firewall.sh
cp ~/dedibox/firewall.sh /etc/init.d/firewall.sh
chmod +x /etc/init.d/firewall.sh
update-rc.d firewall.sh defaults
/etc/init.d/firewall restart

continuer

# postfix
echo -e "\n--- Postfix"
/usr/bin/apt-get -y --force-yes install postfix
sauve_fiv '/etc/aliases'
echo "root: $ADR_MAIL" >> /etc/aliases
echo "root: oss974+dedibox@oss974.com" >> /etc/aliases
newaliases
service postfix restart
echo 'Ceci est test!' | mail -s 'Test Postfix' root

continuer

# fail2ban
echo -e "\n--- Fail2ban"
/usr/bin/apt-get -y --force-yes install fail2ban
sauve_fiv '/etc/fail2ban/jail.conf'
cat <<EOF >/etc/fail2ban/jail.local
[DEFAULT]
ignoreip = 127.0.0.1/8
bantime  = 600
findtime = 600
maxretry = 3
destemail = $ADR_MAIL
action = %(action_mwl)s

[ssh]
enabled  = true
port     = $PORT_SSH
filter   = sshd
action = iptables[name=SSH, port=$PORT_SSH, protocol=tcp]
logpath  = /var/log/auth.log
maxretry = 3
bantime = 1800

EOF
service fail2ban restart

continuer

# cron-apt
echo -e "\n--- CRON-APT"
/usr/bin/apt-get -y --force-yes install cron-apt
sauve_fic '/etc/cron-apt/config'
sed -i 's/# MAILTO="root"/MAILTO="'$ADR_MAIL'"/g' /etc/cron-apt/config

continuer

# logwatch
echo -e "\n--- LOGWATCH"
/usr/bin/apt-get -y --force-yes install logwatch
sed -i 's/logwatch --output mail/logwatch --output mail --mailto '$ADR_MAIL' --detail high/g' /etc/cron.daily/00logwatch

echo "--- "
echo "- Ne pas oublier de reconfigurer 'debconf'"
echo "  > dpkg-reconfigure debconf"
echo "  > Selectionner [Dialog] puis [Hihgt]"

exit 0
