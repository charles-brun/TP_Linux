# Module 5 : Monitoring

Dans ce sujet on va installer un outil plutôt clé en main pour mettre en place un monitoring simple de nos machines.

L'outil qu'on va utiliser est [Netdata](https://learn.netdata.cloud/docs/agent/packaging/installer/methods/kickstart).

➜ **Je vous laisse suivre la doc pour le mettre en place** [ou ce genre de lien](https://wiki.crowncloud.net/?How_to_Install_Netdata_on_Rocky_Linux_9). Vous n'avez pas besoin d'utiliser le "Netdata Cloud" machin truc. Faites simplement une install locale.

Installez-le sur `web.tp2.linux` et `db.tp2.linux`.

```
sudo dnf update
sudo dnf install epel-release -y
sudo dnf install wget

wget -O /tmp/netdata-kickstart.sh https://my-netdata.io/kickstart.sh && sh /tmp/netdata-kickstart.sh

systemctl start netdata
systemctl enable netdata
systemctl status netdata

firewall-cmd --permanent --add-port=19999/tcp
firewall-cmd --reload
```

Une fois en place, Netdata déploie une interface un Web pour avoir moult stats en temps réel, utilisez une commande `ss` pour repérer sur quel port il tourne.

```
sudo ss -laputnr

    tcp   LISTEN    0      4096                  [::]:19999                 [::]:*     users:(("netdata",pid=33608,fd=7))
```

Utilisez votre navigateur pour visiter l'interface web de Netdata `http://<IP_VM>:<PORT_NETDATA>`.

➜ **Configurer Netdata pour qu'il vous envoie des alertes** dans [un salon Discord](https://learn.netdata.cloud/docs/agent/health/notifications/discord) dédié en cas de soucis

```
vim /etc/netdata/health_alarm_notify.conf

        ###############################################################################
        # sending discord notifications

        # note: multiple recipients can be given like this:
        #                  "CHANNEL1 CHANNEL2 ..."

        # enable/disable sending discord notifications
        SEND_DISCORD="YES"

        # Create a webhook by following the official documentation -
        # https://support.discordapp.com/hc/en-us/articles/228383668-Intro-to-Webhooks
        DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/1045293899914166293/8Fiv86VIhIhojoqSE9MUKGTuz6ikYGyUyBV2s2_i0KrFyEvJ2X-SikTB88kWHK0xwF12"

        # if a role's recipients are not configured, a notification will be send to
        # this discord channel (empty = do not send a notification for unconfigured
        # roles):
        DEFAULT_RECIPIENT_DISCORD="alarms"
```

➜ **Vérifier que les alertes fonctionnent** en surchargeant volontairement la machine par exemple (effectuez des *stress tests* de RAM et CPU, ou remplissez le disque volontairement par exemple)

```
sudo dnf install stress-ng
stress-ng --cpu 4
```

![Monitoring](../pics/monit.jpg)