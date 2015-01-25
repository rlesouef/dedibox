#!/bin/bash
# Post installation dedibox
# Sécurisation
# Open Source Services - 01/2015
# GPL
#
# Syntaxe: # su - -c "./secure-02.sh"
# Syntaxe: or # sudo ./secure-02.sh
# 

# Doit etre lance en root
if [ $EUID -ne 0 ]; then
  echo "Le script doit être lancé en root: # sudo $0" 1>&2
  exit 1
fi

# Fonctions
#-----------------------------------
sauve_fic() {
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

# Variables
#-----------------------------------
if [ -f secure.var ]; then
    . secure.var
else
  USER_NAME=""
  ADR_MAIL=""
  PORT_SSH=""
  ADR_IPPUB=""
  ADR_MACPUB=""
  ADR_IPFO=""
  ADR_MACFO=""

  # saisie des variables
  #-----------------------------------
  echo "Saisie des variables:"
  read -e -i "$USER_NAME" -p "Nom utilisateur: " input
  USER_NAME="${input:-$USER_NAME}"
  read -e -i "$ADR_MAIL" -p "Adresse mail pour les rapports de securite: " input
  ADR_MAIL="${input:-$ADR_MAIL}"
  read -e -i "$PORT_SSH" -p "Port SSH: " input
  PORT_SSH="${input:-$PORT_SSH}"
  read -e -i "$ADR_IPPUB" -p "Adresse IP Publique: " input
  ADR_IPPUB="${input:-$ADR_IPPUB}"
  read -e -i "$ADR_MACPUB" -p "Adresse Mac Publique: " input
  ADR_MACPUB="${input:-$ADR_MACPUB}"
  read -e -i "$ADR_IPFO" -p "Adresse IP Failover: " input
  ADR_IPFO="${input:-$ADR_IPFO}"
  read -e -i "$ADR_MACFO" -p "Adresse Mac Failover: " input
  ADR_MACFO="${input:-$ADR_MACFO}"

fi

# sauvegarde des variables dans secure.var
echo "USER_NAME=$USER_NAME" > secure.var
echo "ADR_MAIL=$ADR_MAIL" >> secure.var
echo "PORT_SSH=$PORT_SSH" >> secure.var
echo "ADR_IPPUB=$ADR_IPPUB" >> secure.var
echo "ADR_MACPUB=$ADR_MACPUB" >> secure.var
echo "ADR_IPFO=$ADR_IPFO" >> secure.var
echo "ADR_MACFO=$ADR_MACFO" >> secure.var

echo -e "\n- Récapitulafif des variables saisies:"
echo "    > Utilisateur: $USER_NAME"
echo "    > Adresse mail pour les rapports de securite: $ADR_MAIL"
echo "    > Port SSH: $PORT_SSH"
echo "    > Adresse IP Publique: $ADR_IPPUB"
echo "    > Adresse Mac Publique: $ADR_MACPUB"
echo "    > Adresse IP Failover: $ADR_IPFO"
echo "    > Adresse Mac Failover: $ADR_MACFO"

pose

# postfix
echo -e "\n--- Postfix"
/usr/bin/apt-get remove -y --force-yes --purge postfix mailutils
/usr/bin/apt-get -y --force-yes install postfix mailutils
sauve_fic '/etc/aliases'
echo "root: $ADR_MAIL" >> /etc/aliases
newaliases
service postfix restart
echo 'Ceci est test!' | mail -s 'Test Postfix' root

pose

# fail2ban
echo -e "\n--- Fail2ban"
/usr/bin/apt-get remove -y --force-yes --purge fail2ban
/usr/bin/apt-get -y --force-yes install fail2ban
sauve_fic '/etc/fail2ban/jail.conf'
sauve_fic '/etc/fail2ban/jail.local'
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

[postfix]
enabled  = true
port     = smtp,ssmtp
filter   = postfix
logpath  = /var/log/mail.log

EOF
service fail2ban restart

pose

# cron-apt
echo -e "\n--- CRON-APT"
/usr/bin/apt-get remove -y --force-yes --purge cron-apt
/usr/bin/apt-get -y --force-yes install cron-apt
sauve_fic '/etc/cron-apt/config'
sed -i 's/# MAILTO="root"/MAILTO="'$ADR_MAIL'"/g' /etc/cron-apt/config

pose

# logwatch
echo -e "\n--- LOGWATCH"
/usr/bin/apt-get remove -y --force-yes --purge logwatch
/usr/bin/apt-get -y --force-yes install logwatch
sed -i 's/logwatch --output mail/logwatch --output mail --mailto '$ADR_MAIL' --detail high/g' /etc/cron.daily/00logwatch

echo -e "\n "
echo "- Ne pas oublier de reconfigurer 'debconf'"
echo "  > dpkg-reconfigure debconf"
echo "  > [Dialog] puis [Hihgt]"
echo "- Rappel connexion SSH:"
echo "  > port SSH = $PORT_SSH"
echo "  > utilisateur = $USER_NAME"
echo "- Les mails du systeme seront envoyés sur:"
echo "  > $ADR_MAIL"

exit 0
