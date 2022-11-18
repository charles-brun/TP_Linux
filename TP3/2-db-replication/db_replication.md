Création VM db slave
Installation de mariadb

Sur DB :

```
sudo vim /etc/my.cnf.d/mariadb-server.cnf

    >[mysqld]
        # add follows in [mysqld] section : get binary logs
        log-bin=mysql-bin
        # define server ID (uniq one)
        server-id=101

sudo systemctl restart mariadb
sudo mysql -u root -p

MariaDB [(none)]> grant replication slave on *.* to charlie@'%' identified by 'password'; 
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> flush privileges; 
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> exit
Bye
```

Sur DBslave :

```
sudo vim /etc/my.cnf.d/mariadb-server.cnf

    >[mysqld]
        # add follows in [mysqld] section : get binary logs
        log-bin=mysql-bin
        # define server ID (uniq one)
        server-id=102
        # read only yes
        read_only=1
        # define own hostname
        report-host=dbslave.tp3.linux

sudo systemctl restart mariadb
```

Sur DB :
Création de la backup

```
mkdir /home/mariadb_backup
mariabackup --backup --target-dir /home/mariadb_backup -u root -p root
sudo zip -r mariadb_backup.zip /home/mariadb_backup/
```

Sur DBslave :
Récupération de la backup

```
sudo systemctl stop mariadb
sudo rm -rf /var/lib/mysql/*
sftp charlie@10.102.1.12
unzip mariadb_backup.zip

mariabackup --prepare --target-dir mariadb_backup
sudo mariabackup --copy-back --target-dir mariadb_backup

sudo chown -R mysql. /var/lib/mysql/
sudo systemctl start mariadb

cat mariadb_backup/xtrabackup_binlog_info
    >   mysql-bin.000001        683     []
        mysql-bin.000002        385     0-101-2

sudo mysql -u root -p

MariaDB [(none)]> change master to 
master_host='10.102.1.12',
master_user='charlie',
master_password='password',
master_log_file='mysql-bin.000002',
master_log_pos=385;
Query OK, 0 rows affected (0.191 sec)

MariaDB [(none)]> start slave; 
Query OK, 0 rows affected (0.00 sec)
```

Status :

```
MariaDB [(none)]> show slave status\G
*************************** 1. row ***************************
                Slave_IO_State: Waiting for master to send event
                   Master_Host: 10.102.1.12
                   Master_User: charlie
                   Master_Port: 3306
                 Connect_Retry: 60
               Master_Log_File: mysql-bin.000002
           Read_Master_Log_Pos: 514
                Relay_Log_File: mariadb-relay-bin.000002
                 Relay_Log_Pos: 684
         Relay_Master_Log_File: mysql-bin.000002
              Slave_IO_Running: Yes
             Slave_SQL_Running: Yes
               Replicate_Do_DB:
           Replicate_Ignore_DB:
            Replicate_Do_Table:
        Replicate_Ignore_Table:
       Replicate_Wild_Do_Table:
   Replicate_Wild_Ignore_Table:
                    Last_Errno: 0
                    Last_Error:
                  Skip_Counter: 0
           Exec_Master_Log_Pos: 514
               Relay_Log_Space: 995
               Until_Condition: None
                Until_Log_File:
                 Until_Log_Pos: 0
            Master_SSL_Allowed: No
            Master_SSL_CA_File:
            Master_SSL_CA_Path:
               Master_SSL_Cert:
             Master_SSL_Cipher:
                Master_SSL_Key:
         Seconds_Behind_Master: 0
 Master_SSL_Verify_Server_Cert: No
                 Last_IO_Errno: 0
                 Last_IO_Error:
                Last_SQL_Errno: 0
                Last_SQL_Error:
   Replicate_Ignore_Server_Ids:
              Master_Server_Id: 101
                Master_SSL_Crl:
            Master_SSL_Crlpath:
                    Using_Gtid: No
                   Gtid_IO_Pos:
       Replicate_Do_Domain_Ids:
   Replicate_Ignore_Domain_Ids:
                 Parallel_Mode: optimistic
                     SQL_Delay: 0
           SQL_Remaining_Delay: NULL
       Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
              Slave_DDL_Groups: 1
Slave_Non_Transactional_Groups: 0
    Slave_Transactional_Groups: 0
1 row in set (0.000 sec)
```

Test :
Modif sur DB

```
MariaDB [(none)]> create database yolo;
Query OK, 1 row affected (0.000 sec)
```

Résultat sur DBslave

```
MariaDB [(none)]> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| nextcloud          |
| performance_schema |
| yolo               |
+--------------------+
5 rows in set (0.000 sec)
```
