# Module 7 : Fail2Ban

Fail2Ban c'est un peu le cas d'école de l'admin Linux, je vous laisse Google pour le mettre en place.

C'est must-have sur n'importe quel serveur à peu de choses près. En plus d'enrayer les attaques par bruteforce, il limite aussi l'imact sur les performances de ces attaques, en bloquant complètement le trafic venant des IP considérées comme malveillantes

Faites en sorte que :

- si quelqu'un se plante 3 fois de password pour une co SSH en moins de 1 minute, il est ban

```
[sshd]
enabled = true
port = ssh
action = iptables-multiport
logpath = /var/log/secure
maxretry = 3
findtime = 60
bantime = 600

```

- vérifiez que ça fonctionne en vous faisant ban

```
charlie@10.102.1.11's password:
Permission denied, please try again.
charlie@10.102.1.11's password:
Permission denied, please try again.
charlie@10.102.1.11's password:
charlie@10.102.1.11: Permission denied (publickey,gssapi-keyex,gssapi-with-mic,password).
```

- afficher la ligne dans le firewall qui met en place le ban


- lever le ban avec une commande liée à fail2ban

```
sudo fail2ban-client set sshd unbanip 10.102.1.11
```

> Vous pouvez vous faire ban en effectuant une connexion SSH depuis `web.tp2.linux` vers `db.tp2.linux` par exemple, comme ça vous gardez intacte la connexion de votre PC vers `db.tp2.linux`, et vous pouvez continuer à bosser en SSH.

![Chinese bots](../pics/chinese_bots.webp)