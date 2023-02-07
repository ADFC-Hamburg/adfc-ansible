Borg Backup umziehen und dabei das Repo erhalten.

# Backup deaktivieren

siehe `/etc/cron.d/ansible_adfc-borg` löschen oder auskommentieren

# Borg Keys kopieren
```bash
scp -p -r root@alter-rechner:/root/.config/borg /root/.config/
```

# Config in Git übernehmen
in der host_vars die alten Einstellungen vom alten Rechner aufnehmen.
Wichtig: Wenn der inventory_hostname sich ändert, das `adfc_borg_repo` entsprechend setzen

in `setup-borg.yml` die Hostnamen anpassen

# Ansible Playbook aufrufen

```bash
ansible-playbook -v -l neuer-rechner setup-borg.yml
```

# Das Ansible Status dir kopieren

scp -q -r root@alter-rechner:/usr/local/share/adfc-borg/* /usr/local/share/adfc-borg/

# Testen

```bash
adfc-borg status
adfc-borg list
# Sichern:
adfc-borg cron
# Noch mal Sichern (auf den anderen Rechner)
adfc-borg cron
# Alte Sicherungen löschen
adfc-borg prune
```
