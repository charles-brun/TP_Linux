#!/bin/bash

#Créé le 21 novembre 2022 par Charles BRUN
#Script de création de fichier de sauvegarde pour une base de données SQL

#initialisation des variables
user=db_dumps
password=root
host=localhost
dbname=nextcloud

#récupération du password sur fichier séparé
if [ -f /srv/db_pass ]
then
        source /srv/db_pass
fi

while getopts "u:p:h:d:" option
do
    case $option in
        u)
                user=$OPTARG
                ;;
        p)
                password=$OPTARG
                ;;
        h)
                host=$OPTARG
                ;;
        d)
                dbname=$OPTARG
                ;;
    esac
done

savename=db_$dbname\_$(date +%Y%m%d%H%M%S)

#vérification programme zip installé
if [[ -f /usr/bin/zip ]];
then
  _zip="/usr/bin/zip"
else
  echo "/usr/bin/zip not found. Exiting."
  exit 1
fi

#création du fichier .sql de backup
mysqldump -u $user -p$password -h $host --databases $dbname --add-drop-database > /srv/db_dumps/$savename.sql

if [ $? -eq 0 ]
then
    echo "Fichier de sauvegarde créé : $savename.sql."
else
    echo "Erreur lors de la création du fichier de sauvegarde."
    exit 2
fi

#compression du fichier .sql
$_zip -j /srv/db_dumps/$savename.zip /srv/db_dumps/$savename.sql

if [ $? -eq 0 ]
then
    echo "Fichier de sauvegarde compressé."
    #suppression du fichier .sql
    rm /srv/db_dumps/$savename.sql
else
    echo "Erreur lors de la compression."
    exit 3
fi
