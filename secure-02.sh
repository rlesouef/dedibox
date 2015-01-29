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
sauveFic() {
  if [ ! -f ${1} ]; then
      echo "ERREUR: $1 inexistant!!!"
  else
    if [ ! -f ${1}.0 ]; then
      cp ${1} ${1}.0
      echo "$1 sauvegardé"
    else
      cp ${1}.0 ${1}
      echo "$1 restauré"
    fi
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
/usr/bin/apt-get remove -y --force-yes --purge postfix heirloom-mailx
/usr/bin/apt-get -y --force-yes install postfix heirloom-mailx
sauveFic '/etc/postfix/main.cf'
sauveFic '/etc/aliases'
sed -i 's/inet_interfaces = all/inet_interfaces = loopback-only/' /etc/postfix/main.cf
echo "oss974: root" >> /etc/aliases
echo "root: $ADR_MAIL" >> /etc/aliases
newaliases
service postfix restart
echo 'Ceci est test!' | mail -s 'Test Postfix' root

pose

# fail2ban
echo -e "\n--- Fail2ban"
/usr/bin/apt-get remove -y --force-yes --purge fail2ban
/usr/bin/apt-get -y --force-yes install fail2ban
sauveFic '/etc/fail2ban/jail.conf'
sauveFic '/etc/fail2ban/jail.local'
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

# chkrootkit
echo -e "\n--- CHKROOTKIT"
/usr/bin/apt-get remove -y --force-yes --purge chkrootkit
/usr/bin/apt-get -y --force-yes install chkrootkit
sauveFic '/etc/chkrootkit.conf'
# Vérification des modifications quotidienne :
sed -i 's/RUN_DAILY="false"/RUN_DAILY="true"/; s/DIFF_MODE="false"/DIFF_MODE="true"/' /etc/chkrootkit.conf
echo "pour aller plus loin, voir"
echo "RKHUNTER ou TIGER (qui utilise tripwire pour la signature des binaires et JOHN pour la sécurité des mots de passe)"

pose

# logcheck :
echo -e "\n--- LOGCHECK"
/usr/bin/apt-get remove -y --force-yes --purge logcheck
/usr/bin/apt-get -y --force-yes install logcheck
sauveFic '/etc/logcheck/logcheck.conf'
sed -i 's/SENDMAILTO="logcheck"/SENDMAILTO="'$ADR_MAIL'"/g' /etc/logcheck/logcheck.conf
# vérification quotidienne
sed -i 's/2 \* \* \* \*/59 23 * * */' /etc/cron.d/logcheck

pose

# cron-apt
echo -e "\n--- CRON-APT"
/usr/bin/apt-get remove -y --force-yes --purge cron-apt
/usr/bin/apt-get -y --force-yes install cron-apt
sauveFic '/etc/cron-apt/config'
# Mise à jour de sécurité uniquement :
grep security /etc/apt/sources.list > /etc/apt/sources.list.d/security.list
cat <<EOF >/etc/cron-apt/config
APTCOMMAND=/usr/bin/aptitude
OPTIONS="-o quiet=1 -o Dir::Etc::SourceList=/etc/apt/sources.list.d/security.list"
MAILTO="$ADR_MAIL"
MAILON="always"
EOF
sed -i 's/dist-upgrade -d -y -o/dist-upgrade -y -o/' /etc/cron-apt/action.d/3-download
echo "adapter /etc/cron.d/cron-apt"

pose

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
