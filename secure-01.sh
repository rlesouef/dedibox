#!/bin/bash
# Post installation dedibox
# Sécurisation
# Open Source Services - 01/2015
# GPL
#
# Syntaxe: # su - -c "./secure-01.sh"
# Syntaxe: or # sudo ./secure-01.sh
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
    PORT_SSH="22"
    ADR_IPPUB=""
    ADR_MACPUB=""
    ADR_IPFO=""
    ADR_MACFO=""
fi

clear
echo -e "\n:::::::::::::::::::::::::::::::::::::::::::::::::::"
echo "Pour utiliser les réponses par défaut à toutes les questions lors de l'installation des paquets"
echo "Debconf doit etre positionne sur [Non interactive] et [eleve]"
echo "Pour le positionner, quitter le script et taper :"
echo -e "\tdpkg-reconfigure debconf"

pose

# Affichage des parametres
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

# sauvegarde des variables dans secure.var
echo "USER_NAME=$USER_NAME" > secure.var
echo "ADR_MAIL=$ADR_MAIL" >> secure.var
echo "PORT_SSH=$PORT_SSH" >> secure.var
echo "ADR_IPPUB=$ADR_IPPUB" >> secure.var
echo "ADR_MACPUB=$ADR_MACPUB" >> secure.var
echo "ADR_IPFO=$ADR_IPFO" >> secure.var
echo "ADR_MACFO=$ADR_MACFO" >> secure.var

echo -e "\n- Récapitulafif des variables saisies:"
echo "  > Utilisateur: $USER_NAME"
echo "  > Adresse mail pour les rapports de securite: $ADR_MAIL"
echo "  > Port SSH: $PORT_SSH"
echo "  > Adresse IP Publique: $ADR_IPPUB"
echo "  > Adresse Mac Publique: $ADR_MACPUB"
echo "  > Adresse IP Failover: $ADR_IPFO"
echo "  > Adresse Mac Failover: $ADR_MACFO"

pose

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

pose

# firewall
echo -e "\n--- Firewall"
sed -i 's/^SSH_PORT=.*$/SSH_PORT="'$PORT_SSH'"/g' firewall.sh
sed -i 's/^HN_IP=.*$/HN_IP="'$ADR_IPPUB'"/g' firewall.sh
cp firewall.sh /etc/init.d/firewall.sh
chmod +x /etc/init.d/firewall.sh
update-rc.d firewall.sh defaults

echo -e "\n- Ouvrir une nouvelle connexion SSH"
echo "  > port SSH = $PORT_SSH"
echo "  > utilisateur = $USER_NAME"
echo "- et lancer le script 'secure-02.sh'"
echo " "

/etc/init.d/firewall.sh restart

exit 0
