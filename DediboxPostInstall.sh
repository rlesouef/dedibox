#!/bin/bash
# Mon script de post installation dedibox
#
# Nicolargo - 12/2011
# GPL
#
# Syntaxe: # su - -c "./dediboxpostinstall.sh"
# Syntaxe: or # sudo ./dediboxpostinstall.sh
# 
VERSION="1.00"

# Fonctions
#-----------------------------------
sauve_fic() {
  if [ ! -f ${1} ]; then
      echo "ERREUR: $1 inexistant!!!"
      exit 0
    fi
  if [ ! -f ${1}.0 ]; then
      cp ${1} ${1}.0
      echo "$1 sauvegardé"

  else
    cp ${1}.0 ${1}
    echo "$1 restauré"
  fi
}

# Avriables
#-----------------------------------
LISTE="cron-apt fail2ban logwatch portsentry rkhunter"
# utilisateur
USER_NAME="oss974"
# Adresse mail pour les rapports de securite
ADR_MAIL="root@localhost"
# port SSH
SSH_PORT="22"
# Adresse IP Publique
ADR_IPPUB="62.210.99.213"
# Adresse Mac Publique
ADR_MACPUB="d4:ae:52:cf:34:8b"
# Adresse IP Failover
ADR_IPFO="212.83.163.186"
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
echo "Pour le positionner :"
echo -e "\ndpkg-reconfigure debconf"
echo -n "Souhaitez-vous continuer ? [O/n]"
read suite
if [ "$suite" != "o" ] && [ "$suite" != "O" ]; then
  exit 1
fi

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
read SSH_PORT
echo -e "\n#============================================================================="
echo "# Utilisateur: $USER_NAME"
echo "# Port SSH: $SSH_PORT"
echo "# Adresse mail pour les rapports de securite: $ADR_MAIL"
echo "#============================================================================="
echo " "
echo -n "Souhaitez-vous continuer ? [O/n]"
read suite
if [ "$suite" != "o" ] && [ "$suite" != "O" ]; then
  exit 1
fi

echo " "

# Mise a jour de la liste des depots
#-----------------------------------

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
echo -e "\nInstallation paquets"
/usr/bin/apt-get -y --force-yes install git

# firewall
echo -e "\nFirewall"
git clone https://github.com/rlesouef/dedibox /tmp/dedibox
sed -i 's/PORT="22"/Port="'$SSH_PORT'"/g' /tmp/dedibox/firewall.sh
sed -i 's/HN_IP="1.2.3.4"/HN_IP="'$ADR_IPPUB'"/g' /tmp/dedibox/firewall.sh
exit 0
cp /tmp/dedibox/firewall.sh /etc/init.d/firewall.sh
chmod +x /etc/init.d/firewall.sh
update-rc.d firewall.sh defaults

# SSH
echo -e "\nSSH"
/usr/bin/apt-get -y --force-yes install openssh-server
sauve_fic '/etc/ssh/sshd_config'
sed -i 's/Port 22/Port '$SSH_PORT'/g' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin without-password/PermitRootLogin no/g' /etc/ssh/sshd_config
sed -i 's/X11Forwarding yes/X11Forwarding no/g' /etc/ssh/sshd_config
echo "AllowUsers $USER_NAME" >> /etc/ssh/sshd_config
/etc/init.d/ssh restart

# postfix
/usr/bin/apt-get -y --force-yes install postfix
sauve_fiv '/etc/aliases'
echo "root: $ADR_MAIL" >> /etc/aliases
echo "root: oss974+dedibox@oss974.com" >> /etc/aliases
newaliases
echo 'Ceci est test!' | mail -s 'Test Postfix' root


# fail2ban
echo -e "\nFAIL2BAN"
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
port     = $SSH_PORT
filter   = sshd
action = iptables[name=SSH, port=$SSH_PORT, protocol=tcp]
logpath  = /var/log/auth.log
maxretry = 3
bantime = 1800

EOF
service fail2ban restart

# cron-apt
echo -e "\nCRON-APT"
/usr/bin/apt-get -y --force-yes install cron-apt
sauve_fic '/etc/cron-apt/config'
sed -i 's/# MAILTO="root"/MAILTO="'$ADR_MAIL'"/g' /etc/cron-apt/config

# logwatch
echo -e "\nLOGWATCH"
/usr/bin/apt-get -y --force-yes install logwatch
sed -i 's/logwatch --output mail/logwatch --output mail --mailto '$ADR_MAIL' --detail high/g' /etc/cron.daily/00logwatch

echo "Autres action à faire si besoin:"
echo "- Securisé le serveur avec un Firewall"
echo "  > http://www.debian.org/doc/manuals/securing-debian-howto/ch-sec-services.en.html"
echo "  > https://raw.github.com/nicolargo/debianpostinstall/master/firewall.sh"
echo "- Securisé le daemon SSH"
echo "  > http://www.debian-administration.org/articles/455"
echo "- Permettre l'envoi de mail"
echo "  > http://blog.nicolargo.com/2011/12/debian-et-les-mails-depuis-la-ligne-de-commande.html"

# Fin du script
exit 0
