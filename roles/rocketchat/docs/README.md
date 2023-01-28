# Restore von Rocketchat

Mit ansible aufsetzen, die DB unter /usr/local/share/rocketchat/mongodump restoren.

Dann:

```shell
cd /srv/docker-rocket
# initale Mongodb löschen, die Ansible angelegt hat.
docker rm docker-rocket-mongodb-1
docker volume remove docker-rocket_mongodb_data

# Nur die Mongo DB Instanz neu starten
docker compose up mongodb -d

# Restore
docker exec -i docker-rocket-mongodb-1 sh -c 'mongorestore --archive' < /usr/local/share/rocketchat/mongodump

# Docker neu starten
docker compose down
docker compose up
```

# Notiz vom Umzug 2023-01-28
* Eine Wartungsseite auf neuen RocketChat (Chat2) schalten
* Borgbackup auf alten abschalten

* DNS Record zum Server Chat2 ändern

* Wartungsseite auf alten RocketChat schalten

* Ein letztes DB Backup auf dem alten machen
* Das DB Backup einspielen

* Rocketchat auf dem neuen starten
* Testen via Port 3000
* Lets Encrypt Zertifikat
* Wartungsseite entfernen
* Borgbackup Keys auf neuen kopieren und Backup einschalten