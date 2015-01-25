# Script

## Prérequis

Afin de pouvoir récupérer le script, il faut avoir git d'installé sur votre machine.

Pour l'installer sur une distribution Debian/Ubuntu:

    # apt-get install git

ou

    $ sudo apt-get install git

## Récuperation du script

Se placer dans le répertoire /tmp par exemple, et en root (sudo su):

    # cd /tmp
    # git clone https://github.com/rlesouef/dedibox
    # cd dedibox/
    # chmod o+x secureSrv.sh
    # ./secureSrv.sh

Le script va automatiquement lancer l'installation des paquets nécessaires à la sécurisation du serveur.
Répondre simplement aux questions posées...
