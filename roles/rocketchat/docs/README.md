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

