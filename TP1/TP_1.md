# TP1 : (re)Familiaration avec un système GNU/Linux

Dans ce TP, on va passer en revue des éléments de configurations élémentaires du système.

Vous pouvez effectuer ces actions dans la première VM. On la clonera ensuite avec toutes les configurations pré-effectuées.

Au menu :

- gestion d'utilisateurs
  - sudo
  - SSH et clés
- configuration réseau
- gestion de partitions
- gestion de services

![Heyyyy](./pics/hey.jpeg)

## Sommaire

- [TP1 : (re)Familiaration avec un système GNU/Linux](#tp1--refamiliaration-avec-un-système-gnulinux)
  - [Sommaire](#sommaire)
  - [0. Préparation de la machine](#0-préparation-de-la-machine)
  - [I. Utilisateurs](#i-utilisateurs)
    - [1. Création et configuration](#1-création-et-configuration)
    - [2. SSH](#2-ssh)
  - [II. Partitionnement](#ii-partitionnement)
    - [1. Préparation de la VM](#1-préparation-de-la-vm)
    - [2. Partitionnement](#2-partitionnement)
  - [III. Gestion de services](#iii-gestion-de-services)
  - [1. Interaction avec un service existant](#1-interaction-avec-un-service-existant)
  - [2. Création de service](#2-création-de-service)
    - [A. Unité simpliste](#a-unité-simpliste)
    - [B. Modification de l'unité](#b-modification-de-lunité)

## 0. Préparation de la machine

> **POUR RAPPEL** pour chacune des opérations, vous devez fournir dans le compte-rendu : comment réaliser l'opération ET la preuve que l'opération a été bien réalisée

🌞 **Setup de deux machines Rocky Linux configurées de façon basique.**

- **un accès internet (via la carte NAT)**
  - carte réseau dédiée
  - route par défaut

- **un accès à un réseau local** (les deux machines peuvent se `ping`) (via la carte Host-Only)
  - carte réseau dédiée (host-only sur VirtualBox)
  - les machines doivent posséder une IP statique sur l'interface host-only

```
sudo vim /etc/sysconfig/network-scripts/ifcfg-enp0s8

    NAME=enp0s8
    DEVICE=enp0s8

    BOOTPROTO=static
    ONBOOT=yes

    IPADDR=10.101.1.11
    NETMASK=255.255.255.0

sudo nmcli con reload
sudo nmcli con up enp0s8
```

- **vous n'utilisez QUE `ssh` pour administrer les machines**

- **les machines doivent avoir un nom**
  - référez-vous au mémo
  - les noms que doivent posséder vos machines sont précisés dans le tableau plus bas

```
sudo vim /etc/hostname

      node1.tp1.b2
```

- **utiliser `1.1.1.1` comme serveur DNS**
  - référez-vous au mémo
  - vérifier avec le bon fonctionnement avec la commande `dig`
    - avec `dig`, demander une résolution du nom `ynov.com`
    - mettre en évidence la ligne qui contient la réponse : l'IP qui correspond au nom demandé
    - mettre en évidence la ligne qui contient l'adresse IP du serveur qui vous a répondu

```
sudo vim /etc/sysconfig/network-scripts/ifcfg-enp0s8

    DNS1=1.1.1.1
```

- **les machines doivent pouvoir se joindre par leurs noms respectifs**
  - fichier `/etc/hosts`
  - assurez-vous du bon fonctionnement avec des `ping <NOM>`

```
sudo vim /etc/hosts

    10.101.1.11 node1 node1.tp1.b2
```

- **le pare-feu est configuré pour bloquer toutes les connexions exceptées celles qui sont nécessaires**
  - commande `firewall-cmd`

```
sudo firewall-cmd --list-all
sudo firewall-cmd --remove-service cockpit
sudo firewall-cmd --remove-service dhcpv6-client
```

Pour le réseau des différentes machines (ce sont les IP qui doivent figurer sur les interfaces host-only):

| Name               | IP            |
|--------------------|---------------|
| 🖥️ `node1.tp1.b2` | `10.101.1.11` |
| 🖥️ `node2.tp1.b2` | `10.101.1.12` |
| Votre hôte         | `10.101.1.1`  |

## I. Utilisateurs

[Une section dédiée aux utilisateurs est dispo dans le mémo Linux.](../../cours/memos/commandes.md#gestion-dutilisateurs).

### 1. Création et configuration

🌞 **Ajouter un utilisateur à la machine**, qui sera dédié à son administration

- précisez des options sur la commande d'ajout pour que :
  - le répertoire home de l'utilisateur soit précisé explicitement, et se trouve dans `/home`
  - le shell de l'utilisateur soit `/bin/bash`

```
sudo useradd admin -m -d /home -s /bin/bash
```

- prouvez que vous avez correctement créé cet utilisateur
  - et aussi qu'il a le bon shell et le bon homedir

```
cat /etc/passwd
    admin:x:1001:1001::/home/admin:/bin/bash

```

🌞 **Créer un nouveau groupe `admins`** qui contiendra les utilisateurs de la machine ayant accès aux droits de `root` *via* la commande `sudo`.

Pour permettre à ce groupe d'accéder aux droits `root` :

- il faut modifier le fichier `/etc/sudoers`
- on ne le modifie jamais directement à la main car en cas d'erreur de syntaxe, on pourrait bloquer notre accès aux droits administrateur
- la commande `visudo` permet d'éditer le fichier, avec un check de syntaxe avant fermeture
- ajouter une ligne basique qui permet au groupe d'avoir tous les droits (inspirez vous de la ligne avec le groupe `wheel`)

```
sudo visudo
    %admins ALL=(ALL)       ALL

(shift z z pour fermer)
```

🌞 **Ajouter votre utilisateur à ce groupe `admins`**

> Essayez d'effectuer une commande avec `sudo` peu importe laquelle, juste pour tester que vous avez le droit d'exécuter des commandes sous l'identité de `root`. Vous pouvez aussi utiliser `sudo -l` pour voir les droits `sudo` auquel votre utilisateur courant a accès.

---

1. Utilisateur créé et configuré
2. Groupe `admins` créé
3. Groupe `admins` ajouté au fichier `/etc/sudoers`
4. Ajout de l'utilisateur au groupe `admins`

### 2. SSH

[Une section dédiée aux clés SSH existe dans le cours.](../../cours/SSH/README.md)

Afin de se connecter à la machine de façon plus sécurisée, on va configurer un échange de clés SSH lorsque l'on se connecte à la machine.

🌞 **Pour cela...**

- il faut générer une clé sur le poste client de l'administrateur qui se connectera à distance (vous :) )
  - génération de clé depuis VOTRE poste donc
  - sur Windows, on peut le faire avec le programme `puttygen.exe` qui est livré avec `putty.exe`
- déposer la clé dans le fichier `/home/<USER>/.ssh/authorized_keys` de la machine que l'on souhaite administrer
  - vous utiliserez l'utilisateur que vous avez créé dans la partie précédente du TP
  - on peut le faire à la main
  - ou avec la commande `ssh-copy-id`

🌞 **Assurez vous que la connexion SSH est fonctionnelle**, sans avoir besoin de mot de passe.

## II. Partitionnement

[Il existe une section dédiée au partitionnement dans le cours](../../cours/part/)

### 1. Préparation de la VM

⚠️ **Uniquement sur `node1.tp1.b2`.**

Ajout de deux disques durs à la machine virtuelle, de 3Go chacun.

### 2. Partitionnement

⚠️ **Uniquement sur `node1.tp1.b2`.**

🌞 **Utilisez LVM** pour...

- agréger les deux disques en un seul *volume group*
- créer 3 *logical volumes* de 1 Go chacun
- formater ces partitions en `ext4`
- monter ces partitions pour qu'elles soient accessibles aux points de montage `/mnt/part1`, `/mnt/part2` et `/mnt/part3`.

🌞 **Grâce au fichier `/etc/fstab`**, faites en sorte que cette partition soit montée automatiquement au démarrage du système.

✨**Bonus** : amusez vous avez les options de montage. Quelques options intéressantes :

- `noexec`
- `ro`
- `user`
- `nosuid`
- `nodev`
- `protect`

## III. Gestion de services

Au sein des systèmes GNU/Linux les plus utilisés, c'est *systemd* qui est utilisé comme gestionnaire de services (entre autres).

Pour manipuler les services entretenus par *systemd*, on utilise la commande `systemctl`.

On peut lister les unités `systemd` actives de la machine `systemctl list-units -t service`.

**Référez-vous au mémo pour voir les autres commandes `systemctl` usuelles.**

## 1. Interaction avec un service existant

⚠️ **Uniquement sur `node1.tp1.b2`.**

Parmi les services système déjà installés sur Rocky, il existe `firewalld`. Cet utilitaire est l'outil de firewalling de Rocky.

🌞 **Assurez-vous que...**

- l'unité est démarrée
- l'unitée est activée (elle se lance automatiquement au démarrage)

```
sudo systemctl status firewalld
```

## 2. Création de service

![Création de service systemd](./pics/create_service.png)

### A. Unité simpliste

⚠️ **Uniquement sur `node1.tp1.b2`.**

🌞 **Créer un fichier qui définit une unité de service** 

- le fichier `web.service`
- dans le répertoire `/etc/systemd/system`

Déposer le contenu suivant :

```
[Unit]
Description=Very simple web service

[Service]
ExecStart=/usr/bin/python3 -m http.server 8888

[Install]
WantedBy=multi-user.target
```

Le but de cette unité est de lancer un serveur web sur le port 8888 de la machine. **N'oubliez pas d'ouvrir ce port dans le firewall.**

Une fois l'unité de service créée, il faut demander à *systemd* de relire les fichiers de configuration :

```bash
$ sudo systemctl daemon-reload
```

Enfin, on peut interagir avec notre unité :

```bash
$ sudo systemctl status web
$ sudo systemctl start web
$ sudo systemctl enable web
```

🌞 **Une fois le service démarré, assurez-vous que pouvez accéder au serveur web**

- avec un navigateur depuis votre PC
- ou la commande `curl` depuis l'autre machine (je veux ça dans le compte-rendu :3)

```
[charlie@node2 ~]$ curl 10.101.1.11:8888
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Directory listing for /</title>
</head>
<body>
<h1>Directory listing for /</h1>
<hr>
<ul>
<li><a href="afs/">afs/</a></li>
<li><a href="bin/">bin@</a></li>
<li><a href="boot/">boot/</a></li>
<li><a href="dev/">dev/</a></li>
<li><a href="etc/">etc/</a></li>
<li><a href="home/">home/</a></li>
<li><a href="lib/">lib@</a></li>
<li><a href="lib64/">lib64@</a></li>
<li><a href="media/">media/</a></li>
<li><a href="mnt/">mnt/</a></li>
<li><a href="opt/">opt/</a></li>
<li><a href="proc/">proc/</a></li>
<li><a href="root/">root/</a></li>
<li><a href="run/">run/</a></li>
<li><a href="sbin/">sbin@</a></li>
<li><a href="srv/">srv/</a></li>
<li><a href="sys/">sys/</a></li>
<li><a href="tmp/">tmp/</a></li>
<li><a href="usr/">usr/</a></li>
<li><a href="var/">var/</a></li>
</ul>
<hr>
</body>
</html>
```

- sur l'IP de la VM, port 8888

### B. Modification de l'unité

🌞 **Préparez l'environnement pour exécuter le mini serveur web Python**

- créer un utilisateur `web`
- créer un dossier `/var/www/meow/`
- créer un fichier dans le dossier `/var/www/meow/` (peu importe son nom ou son contenu, c'est pour tester)
- montrez à l'aide d'une commande les permissions positionnées sur le dossier et son contenu

```
[charlie@node1 ~]$ ls -l /var/www/
total 0
drwx------. 2 web web 18 Nov 14 18:58 meow
```

> Pour que tout fonctionne correctement, il faudra veiller à ce que le dossier et le fichier appartiennent à l'utilisateur `web` et qu'il ait des droits suffisants dessus.

```
 sudo chown web:web /var/www/meow/
 sudo chmod 700 /var/www/meow/
```

🌞 **Modifiez l'unité de service `web.service` créée précédemment en ajoutant les clauses**

- `User=` afin de lancer le serveur avec l'utilisateur `web` dédié
- `WorkingDirectory=` afin de lancer le serveur depuis le dossier créé au dessus : `/var/www/meow/`
- ces deux clauses sont à positionner dans la section `[Service]` de votre unité

🌞 **Vérifiez le bon fonctionnement avec une commande `curl`**

```
[charlie@node2 ~]$ curl 10.101.1.11:8888
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Directory listing for /</title>
</head>
<body>
<h1>Directory listing for /</h1>
<hr>
<ul>
<li><a href="toto">toto</a></li>
</ul>
<hr>
</body>
</html>
```