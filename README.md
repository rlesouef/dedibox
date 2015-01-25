# Script

## Prérequis

Afin de pouvoir récupérer le script, il faut avoir git d'installé sur votre machine.

Pour l'installer sur une distribution Debian/Ubuntu:

    # apt-get install git

ou

    $ sudo apt-get install git

Les scripts secure-01.sh et secure-01.sh doivent être lancés successivement.

## Récuperation du script

Créer une connexion SSH et en root (sudo su):

    # rm -R /tmp/dedibox
    # cd /tmp
    # git clone https://github.com/rlesouef/dedibox
    # cd dedibox/
    # chmod o+x secure-01.sh
    # chmod o+x secure-02.sh
    # ./secure-01.sh

Créer une nouvelle connexion SSH avec les paramètres affichés par le script secure-01.sh et en root (sudo su):

    # cd /tmp/dedibox
    # ./secure-02.sh

Répondre simplement aux questions posées...
