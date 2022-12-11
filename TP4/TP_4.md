# TP4 : Conteneurs

Dans ce TP on va aborder plusieurs points autour de la conteneurisation : 

- Docker et son empreinte sur le système
- Manipulation d'images
- `docker-compose`

![Headaches](./pics/headaches.jpg)

# Sommaire

- [TP4 : Conteneurs](#tp4--conteneurs)
- [Sommaire](#sommaire)
- [0. Prérequis](#0-prérequis)
  - [Checklist](#checklist)
- [I. Docker](#i-docker)
  - [1. Install](#1-install)
  - [2. Vérifier l'install](#2-vérifier-linstall)
  - [3. Lancement de conteneurs](#3-lancement-de-conteneurs)
- [II. Images](#ii-images)
- [III. `docker-compose`](#iii-docker-compose)
  - [1. Intro](#1-intro)
  - [2. Make your own meow](#2-make-your-own-meow)

# 0. Prérequis

➜ Machines Rocky Linux

➜ Un unique host-only côté VBox, ça suffira. **L'adresse du réseau host-only sera `10.104.1.0/24`.**

➜ Chaque **création de machines** sera indiquée par **l'emoji 🖥️ suivi du nom de la machine**

➜ Si je veux **un fichier dans le rendu**, il y aura l'**emoji 📁 avec le nom du fichier voulu**. Le fichier devra être livré tel quel dans le dépôt git, ou dans le corps du rendu Markdown si c'est lisible et correctement formaté.

## Checklist

A chaque machine déployée, vous **DEVREZ** vérifier la 📝**checklist**📝 :

- [x] IP locale, statique ou dynamique
- [x] hostname défini
- [x] firewall actif, qui ne laisse passer que le strict nécessaire
- [x] SSH fonctionnel avec un échange de clé
- [x] accès Internet (une route par défaut, une carte NAT c'est très bien)
- [x] résolution de nom
- [x] SELinux désactivé (vérifiez avec `sestatus`, voir [mémo install VM tout en bas](https://gitlab.com/it4lik/b2-reseau-2022/-/blob/main/cours/memo/install_vm.md#4-pr%C3%A9parer-la-vm-au-clonage))

**Les éléments de la 📝checklist📝 sont STRICTEMENT OBLIGATOIRES à réaliser mais ne doivent PAS figurer dans le rendu.**

# I. Docker

🖥️ Machine **docker1.tp4.linux**

## 1. Install

🌞 **Installer Docker sur la machine**

- en suivant [la doc officielle](https://docs.docker.com/engine/install/)
- démarrer le service `docker` avec une commande `systemctl`
- ajouter votre utilisateur au groupe `docker`
  - cela permet d'utiliser Docker sans avoir besoin de l'identité de `root`
  - avec la commande : `sudo usermod -aG docker $(whoami)`
  - déconnectez-vous puis relancez une session pour que le changement prenne effet

## 2. Vérifier l'install

➜ **Vérifiez que Docker est actif est disponible en essayant quelques commandes usuelles :**

```bash
# Info sur l'install actuelle de Docker
$ docker info

# Liste des conteneurs actifs
$ docker ps
# Liste de tous les conteneurs
$ docker ps -a

# Liste des images disponibles localement
$ docker images

# Lancer un conteneur debian
$ docker run debian

# -d sert à mettre un conteneur en tâche de fond (-d pour daemon)
$ docker run -d debian sleep 99999

# à l'inverse, -it sert à avoir un shell interactif (incompatible avec -d)
$ docker run -it debian bash

# Consulter les logs d'un conteneur
$ docker ps # on repère l'ID/le nom du conteneur voulu
$ docker logs <ID_OR_NAME>
$ docker logs -f <ID_OR_NAME> # suit l'arrivée des logs en temps réel

# Exécuter un processus dans un conteneur actif
$ docker ps # on repère l'ID/le nom du conteneur voulu
$ docker exec <ID_OR_NAME> <COMMAND>
$ docker exec <ID_OR_NAME> ls
$ docker exec -it <ID_OR_NAME> bash # permet de récupérer un shell bash dans le conteneur ciblé
```

➜ **Explorer un peu le help**, si c'est pas le man :

```bash
$ docker --help
$ docker run --help
$ man docker
```

## 3. Lancement de conteneurs

La commande pour lancer des conteneurs est `docker run`.

Certaines options sont très souvent utilisées :

```bash
# L'option --name permet de définir un nom pour le conteneur
$ docker run --name web nginx

# L'option -d permet de lancer un conteneur en tâche de fond
$ docker run --name web -d nginx

# L'option -v permet de partager un dossier/un fichier entre l'hôte et le conteneur
$ docker run --name web -d -v /path/to/html:/usr/share/nginx/html nginx

# L'option -p permet de partager un port entre l'hôte et le conteneur
$ docker run --name web -d -v /path/to/html:/usr/share/nginx/html -p 8888:80 nginx
# Dans l'exemple ci-dessus, le port 8888 de l'hôte est partagé vers le port 80 du conteneur
```

🌞 **Utiliser la commande `docker run`**

- lancer un conteneur `nginx`
  - l'app NGINX doit avoir un fichier de conf personnalisé
  - l'app NGINX doit servir un fichier `index.html` personnalisé
  - l'application doit être joignable grâce à un partage de ports
  - vous limiterez l'utilisation de la RAM et du CPU de ce conteneur
  - le conteneur devra avoir un nom

> Tout se fait avec des options de la commande `docker run`.

```
docker run -d --memory="512m" --cpus="1.0" --name web -v $(pwd)/index.html:/usr/share/nginx/html/index.html -v $(pwd)/nginx.conf:/etc/nginx/conf.d/nginx.conf nginx
```

Petit rappel de fonctionnement sur l'application NGINX : 

- le fichier de conf par défaut se trouve dans `/etc/nginx/nginx.conf`
- si vous ouvrez ce fichier, vous constaterez qu'il inclut tout ce qu'il y a dans `/etc/nginx/conf.d`
  - pour que les fichiers de ce dossier soient inclus, ils doivent porter l'extension `.conf`
- il "suffit" donc 
  - de créer un fichier de conf NGINX sur l'hôte
    - il porte l'extension `.conf`
    - il comporte une conf minimale pour écouter sur un port et servir un site dans un dossier précis
  - grâce à une option `-v ...` sur le `docker run`
    - de poser votre fichier de conf dans `/etc/nginx/conf.d/`
- un fichier de conf NGINX minimal pour faire ça est aussi simple que :

```nginx
server {
  # on définit le port où NGINX écoute dans le conteneur
  listen 9999;
  
  # on définit le chemin vers la racine web
  # dans ce dossier doit se trouver un fichier index.html
  root /var/www/tp4; 
}
```


# II. Images

La construction d'image avec Docker est basée sur l'utilisation de fichiers `Dockerfile`.

L'idée est la suivante :

- vous créez un dossier de travail
- vous vous déplacez dans ce dossier de travail
- vous créez un fichier `Dockerfile`
  - il contient les instructions pour construire une image
  - `FROM` : indique l'image de base
  - `RUN` : indique des opérations à effectuer dans l'image de base
- vous exécutez une commande `docker build . -t <IMAGE_NAME>`
- une image est produite, visible avec la commande `docker images`

## Exemple de Dockerfile et utilisation

Exemple d'un Dockerfile qui :

- se base sur une image ubuntu
- la met à jour
- installe nginx

```bash
$ cat Dockerfile
FROM ubuntu

RUN apt update -y

RUN apt install -y nginx
```

Une fois ce fichier créé, on peut :

```bash
$ ls
Dockerfile

$ docker build . -t my_own_nginx 

$ docker images

$ docker run -p 8888:80 my_own_nginx nginx -g "daemon off;"

$ curl localhost:8888
$ curl <IP_VM>:8888
```

> La commande `nginx -g "daemon off;"` permet de lancer NGINX au premier-plan, et ainsi demande à notre conteneur d'exécuter le programme NGINX à son lancement.

Plutôt que de préciser à la main à chaque `docker run` quelle commande doit lancer le conteneur (notre `nginx -g "daemon off;"` en fin de ligne ici), on peut, au moment du `build` de l'image, choisir d'indiquer que chaque conteneur lancé à partir de cette image lancera une commande donneé.

Il faut, pour cela, modifier le Dockerfile :

```bash
$ cat Dockerfile
FROM ubuntu

RUN apt update -y

RUN apt install -y nginx

CMD [ "/usr/sbin/nginx", "-g", "daemon off;" ]
```

```bash
$ ls
Dockerfile

$ docker build . -t my_own_nginx

$ docker images

$ docker run -p 8888:80 my_own_nginx

$ curl localhost:8888
$ curl <IP_VM>:8888
```


![Waiting for Docker](./pics/waiting_for_docker.jpg)

## 2. Construisez votre propre Dockerfile

🌞 **Construire votre propre image**

- image de base (celle que vous voulez : debian, alpine, ubuntu, etc.)
  - une image du Docker Hub
  - qui ne porte aucune application par défaut
- vous ajouterez
  - mise à jour du système
  - installation de Apache (pour les systèmes debian, le serveur Web apache s'appelle `apache2` et non pas `httpd` comme sur Rocky)
  - page d'accueil Apache HTML personnalisée

Dockerfile :

```
FROM debian

RUN apt update -y

RUN apt install -y apache2

COPY apache2.conf /etc/apache2/apache2.conf

COPY index.html /var/www/html/index.html

ADD . /etc/apache2/logs/

CMD [ "apache2", "-D", "FOREGROUND" ]
```

➜ Fichier de conf pour Apache (à positionner dans `/etc/apache2/apache2.conf`) :

```apache2
# on définit un port sur lequel écouter
Listen 80

# on charge certains modules Apache strictement nécessaires à son bon fonctionnement
LoadModule mpm_event_module "/usr/lib/apache2/modules/mod_mpm_event.so"
LoadModule dir_module "/usr/lib/apache2/modules/mod_dir.so"
LoadModule authz_core_module "/usr/lib/apache2/modules/mod_authz_core.so"

# on indique le nom du fichier HTML à charger par défaut
DirectoryIndex index.html
# on indique le chemin où se trouve notre site
DocumentRoot "/var/www/html/"

# quelques paramètres pour les logs
ErrorLog "logs/error.log"
LogLevel warn

ServerName 10.104.1.2
```

Création de l'image et lancement d'une instance :

```
docker build . -t apache
docker run -p 8888:80 apache
```


📁 **`Dockerfile`**

# III. `docker-compose`

## 1. Intro

➜ **Installer `docker-compose` sur la machine**

- en suivant [la doc officielle](https://docs.docker.com/compose/install/)

`docker-compose` est un outil qui permet de lancer plusieurs conteneurs en une seule commande.

> En plus d'être pratique, il fournit des fonctionnalités additionnelles, liés au fait qu'il s'occupe à lui tout seul de lancer tous les conteneurs. On peut par exemple demander à un conteneur de ne s'allumer que lorsqu'un autre conteneur est devenu "healthy". Idéal pour lancer une application après sa base de données par exemple.

Le principe de fonctionnement de `docker-compose` :

- on écrit un fichier qui décrit les conteneurs voulus
  - c'est le `docker-compose.yml`
  - tout ce que vous écriviez sur la ligne `docker run` peut être écrit sous la forme d'un `docker-compose.yml`
- on se déplace dans le dossier qui contient le `docker-compose.yml`
- on peut utiliser les commandes `docker-compose` :

```bash
# Allumer les conteneurs définis dans le docker-compose.yml
$ docker-compose up
$ docker-compose up -d

# Eteindre
$ docker-compose down

# Explorer un peu le help, il y a d'autres commandes utiles
$ docker-compose --help
```

La syntaxe du fichier peut par exemple ressembler à :

```yml
version: "3.8"

services:
  db:
    image: mysql:5.7
    restart: always
    ports:
      - '3306:3306'
    volumes:
      - "./db/mysql_files:/var/lib/mysql"
    environment:
      MYSQL_ROOT_PASSWORD: beep
      MYSQL_DATABASE: bip
      MYSQL_USER: bap
      MYSQL_PASSWORD: boop

  nginx:
    image: nginx
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    restart: unless-stopped
```

> Pour connaître les variables d'environnement qu'on peut passer à un conteneur, comme `MYSQL_ROOT_PASSWORD` au dessus, il faut se rendre sur la doc de l'image en question, sur le Docker Hub par exemple.

## 2. Make your own meow

Pour cette partie, vous utiliserez une application à vous que vous avez sous la main.

N'importe quelle app fera le taff, un truc dév en cours, en temps perso, au taff, peu importe.

Peu importe le langage aussi ! Go, Python, PHP (désolé des gros mots), Node (j'ai déjà dit désolé pour les gros mots ?), ou autres.

🌞 **Conteneurisez votre application**

- créer un `Dockerfile` maison qui porte l'application
- créer un `docker-compose.yml` qui permet de lancer votre application
- vous préciserez dans le rendu les instructions pour lancer l'application
  - indiquer la commande `git clone`
  - le `cd` dans le bon dossier
  - la commande `docker build` pour build l'image
  - la commande `docker-compose` pour lancer le(s) conteneur(s)

Dockerfile : ![Dockerfile](./app/Dockerfile)

```
docker run -p 10.104.1.2:8888:8080 go
```

📁 📁 `app/Dockerfile` et `app/docker-compose.yml`. Je veux un sous-dossier `app/` sur votre dépôt git avec ces deux fichiers dedans :)