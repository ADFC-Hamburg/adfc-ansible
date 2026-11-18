# docker_compose_project

Verteilt die Compose Projekte `docker_compose_project_<name>` aus den
group_vars (`group_vars/tools_2023/*.yml`) auf die Tools-Server.

Die Rolle läuft nur auf dem ersten Host des Plays und führt alle Aktionen per
`delegate_to` auf dem jeweiligen Server aus. Projekte werden nacheinander
bearbeitet, d.h. es ist immer nur ein Projekt gleichzeitig kurz nicht
erreichbar. Der HAProxy auf den Loadbalancern prüft alle Tools-Server per
Healthcheck und schickt den Traffic automatisch an den Server, auf dem das
Projekt gerade läuft.

## Aufruf

```sh
# alles
ansible-playbook playbooks/tools-docker-only.yml
# nur ein / einige Projekte
ansible-playbook playbooks/tools-docker-only.yml -e docker_compose_only=rocket
ansible-playbook playbooks/tools-docker-only.yml -e docker_compose_only=rocket,wiki
# nur anzeigen, was passieren würde
ansible-playbook playbooks/tools-docker-only.yml -e docker_compose_plan_only=true
```

## Backup bei Änderungen

Ändert sich das Compose File eines Projekts mit `hetzner_volumes`, wird für
jedes Volume ein Backup Volume `backup-<volume>-<zeitstempel>` angelegt
(Label `adfc-compose-backup=true`, `compose-project=<name>`):

1. `docker compose pull`
2. Backup Volume anlegen, mounten, `rsync` im laufenden Betrieb
3. `docker compose down`
4. zweiter `rsync`, Backup Volume aushängen und vom Server abhängen
5. `docker compose up -d`

Das Backup Volume bleibt in der Hetzner Cloud bestehen. Abschalten pro Projekt
mit `backup_on_change: false`. Aufräumen:

```sh
ansible-playbook playbooks/docker-compose-delete-backups.yml [-e docker_compose_only=rocket] [-e dry_run=true]
```

Zurückspielen geht manuell: Backup Volume an den Server hängen, Projekt
stoppen, Daten per rsync zurückkopieren, `compose.old` nach `compose.yml`
kopieren, starten.

## Projekte verschieben

`nodes` in den group_vars auf den neuen Server ändern und die Rolle laufen
lassen. Projekte mit Hetzner Volumes dürfen nur einen Node haben und werden so
verschoben:

1. Ziel vorbereiten: Compose File, Secrets (von der Quelle kopiert), `docker compose pull`
2. ggf. Backup (nur wenn sich das Compose File dabei auch ändert)
3. Quelle stoppen, Hetzner Volumes aushängen, abhängen, am Ziel anhängen und mounten
4. Ziel starten, auf der Quelle `compose.yml` nach `compose.yml.moved` umbenennen

Lokale Docker Volumes (Volumes im `compose_block`, die nicht als
`hetzner_volumes` unter `/var/lib/docker/volumes/docker-<projekt>_<volume>`
gemountet sind) sind nicht erlaubt; die Rolle bricht dann ab, bevor sie etwas
ändert.

Um ein lokales Volume umzustellen, einfach einen Eintrag in `hetzner_volumes`
ergänzen. Beim nächsten Lauf wird das Hetzner Volume angelegt, die vorhandenen
Daten per rsync übernommen (live, Projekt stoppen, final), die alten lokalen
Daten nach `<mount>.pre-hetzner-<zeitstempel>` verschoben, das Volume gemountet
und das Projekt wieder gestartet. Verschieben auf einen anderen Server geht
erst, wenn alle Hetzner Volumes des Projekts existieren.

Projekte ohne Volumes werden auf neuen Servern zuerst gestartet und danach auf
den alten gestoppt (`compose.yml.removed`).

## Server für ein Update leer räumen

```sh
ansible-playbook playbooks/tools-docker-only.yml -e docker_compose_evacuate=tools1.hamburg.adfc.de
# ... Update / Reboot von tools1 ...
ansible-playbook playbooks/tools-docker-only.yml
```

`docker_compose_evacuate` überschreibt `nodes` aus den group_vars: der Server
wird aus allen `nodes` entfernt; bleibt kein Node übrig, wird der erste
übrige Tools-Server genommen. Der zweite Lauf ohne Variable bringt alles
wieder an den in den group_vars konfigurierten Platz.

Hinweis: Mit `-l` lässt sich die Rolle nicht auf einen Server beschränken, sie
verwaltet immer alle Server aus `docker_compose_hosts` (Default: Gruppe
`tools_2023`).
