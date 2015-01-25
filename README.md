# Script

## Prérequis

Afin de pouvoir récupérer le script, il faut avoir git d'installé sur votre machine.

Pour l'installer sur une distribution Debian/Ubuntu:

    # apt-get install git

ou

    $ sudo apt-get install git

## Récuperation du script

Placez vous tout d'abord dans le répertoire /tmp par exemple:

    $ cd /tmp
    $ git clone https://github.com/rlesouef/dedibox
    $ cd dedibox/
    $ chmod o+x secureSrv.sh
    $ ./secureSrv.sh

Le script va automatiquement lancer l'installation des paquets nécessaires à la sécurisation du serveur.
Répondez simplement aux questions qui vous seront posées.
