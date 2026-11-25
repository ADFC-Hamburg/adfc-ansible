# Matratzen: HA-Konzept mit haproxy und Let's Encrypt

Diese Seite beschreibt, wie die Proxmox-Server in der Geschäftsstelle
(„Matratzen“) mit nur einer öffentlichen IPv4-Adresse ausfallsicher
betrieben werden und wie die Let's-Encrypt-Zertifikate dabei erneuert
und verteilt werden.

Stand: 2026-11-16 (matratze02 und matratze03 aktiv, matratze01 wegen
Hardwareschaden ausgebaut).

## Überblick

```text
                 Internet
                    │
        31.172.106.205 (eine IPv4)
                    │
               ┌─────────┐   Port 80/443 per NAT auf
               │ Fritzbox│   EINE Matratze (umschaltbar)
               └────┬────┘
      192.168.123.0/24
     ┌──────────────┼──────────────────────┐
     │              │                      │
┌────┴──────┐  ┌────┴──────┐   ┌───────────┴────────────┐
│matratze02 │  │matratze03 │   │ VMs: ucs-master, dreicx,│
│ .91       │  │ .92       │   │ nextcloud-srv, …        │
│ haproxy   │  │ haproxy   │   └─────────────────────────┘
│ dehydrated│  │ dehydrated│
└───────────┘  └───────────┘
```

- Alle DNS-Namen unter `gst.hamburg.adfc.de` zeigen per CNAME auf
  `gst.hamburg.adfc.de` (31.172.106.205). Die Zone liegt bei deSEC.
- Die Fritzbox leitet Port 80 und 443 an **eine** Matratze weiter.
- Auf **jeder** Matratze läuft ein haproxy mit **identischer**
  Konfiguration. Jeder haproxy kennt alle Backends
  (Gruppe `haproxy_gst_backends` im Inventory).
- Fällt die aktive Matratze aus, wird in der Fritzbox die
  Portweiterleitung auf die andere Matratze umgestellt. Mehr ist im
  Normalfall nicht nötig.

Playbook: [`playbooks/matratze.yml`](../playbooks/matratze.yml)
(Rollen `dehydrated` und `haproxy`, Gruppe `proxmox_gst`).

## Zertifikate erneuern (HTTP-01)

Es gibt zwei Arten von Backends:

- **VMs** (`ucs-master`, `dreicx`, `nextcloud-srv`): holen ihre
  Zertifikate selbst, z. B. per certbot auf Port 80. Variable
  `haproxy_lets_encrypt_domains`, Default ist der Hostname.
- **Matratzen**: holen ihre Zertifikate per `dehydrated`. Variable
  `haproxy_dehydrated_domains`.

Ablauf einer Erneuerung auf einer Matratze:

1. Cron (`/etc/cron.d/ansible_dehydrated`, am 1. und 15. des Monats)
   startet `dehydrated --cron`. Erneuert wird erst, wenn das Zertifikat
   weniger als 30 Tage gültig ist.
2. Der `startup_hook` startet `dehydrated-http.service`: ein
   `python3 -m http.server` auf `<ansible_host>:180`, der
   `/var/lib/dehydrated/acme-challenges` ausliefert.
3. Let's Encrypt ruft
   `http://<name>/.well-known/acme-challenge/<token>` auf. Die Anfrage
   kommt über die Fritzbox bei der **aktiven** Matratze an.
4. Deren haproxy leitet sie anhand des `Host`-Headers an die
   **zuständige** Matratze weiter (`<ansible_host>:180`), auch wenn
   das die andere Matratze ist. Dadurch klappt die Erneuerung auf
   beiden Matratzen, egal wohin die Fritzbox gerade zeigt.
5. Der `deploy_hook` kopiert das Zertifikat nach
   `/etc/pve/local/pveproxy-ssl.{pem,key}` und startet `pveproxy` neu
   (Proxmox-Weboberfläche auf Port 8006).
6. Der `exit_hook` stoppt `dehydrated-http.service` wieder.

Die Hooks und `dehydrated_acme_listen_ip` stehen in
[`group_vars/proxmox_gst.yml`](../group_vars/proxmox_gst.yml).

## Zertifikate verteilen (fetch-certs)

Der haproxy terminiert TLS selbst und braucht deshalb die Zertifikate
**aller** Backends in `/etc/haproxy/certs/`.

- Jede Matratze hat einen eigenen SSH-Key
  (`/usr/local/share/harpoxy-key-copy/ssh-key`).
- Auf jedem Backend ist dieser Key mit
  `command="/usr/local/sbin/haproxy_keycat"` eingeschränkt. Das Skript
  gibt nur `fullchain.pem` und `privkey.pem` aus (Liste in
  `haproxy_cert_and_key_files` der jeweiligen host_vars).
- `/usr/local/share/harpoxy-key-copy/fetch-certs` läuft täglich um
  3 Uhr, holt alle Zertifikate ab und startet haproxy neu, wenn sich
  eines geändert hat.
- Nur wenn **alle** Abrufe geklappt haben, werden Dateien gelöscht,
  die älter als 20 Minuten sind (z. B. von entfernten Hosts).

Dadurch hat die nicht aktive Matratze jederzeit alle aktuellen
Zertifikate und kann sofort übernehmen.

## Gemeinsame Namen

`matratze.gst.hamburg.adfc.de` (Proxmox über beide Matratzen) und
`haproxy.gst.hamburg.adfc.de` (haproxy-Statistik) gehören zu keiner
einzelnen Matratze. Sie stehen **nur** in den
`haproxy_dehydrated_domains` von matratze02:

```yaml
# host_vars/matratze02.gst.hamburg.adfc.de.yml
haproxy_dehydrated_domains:
  - matratze02.gst.hamburg.adfc.de
  - matratze.gst.hamburg.adfc.de
  - haproxy.gst.hamburg.adfc.de

# host_vars/matratze03.gst.hamburg.adfc.de.yml
haproxy_dehydrated_domains:
  - matratze03.gst.hamburg.adfc.de
```

Sie dürfen **nicht** bei mehreren Matratzen eingetragen werden:

- haproxy erzeugt pro Name eine `use_backend`-Regel. Bei doppelten
  Namen gewinnt immer die erste Regel, die Prüfung landet also nie bei
  der zweiten Matratze.
- `domains.txt` enthält alle Namen in **einer** Zeile, dehydrated
  macht daraus **ein** Zertifikat. Scheitert ein Name, scheitert das
  ganze Zertifikat, also auch das für den eigenen Hostnamen.

Über `fetch-certs` hat trotzdem auch matratze03 das Zertifikat für die
gemeinsamen Namen. Es wird aber nur auf matratze02 erneuert.

## Notfall: Matratze fällt aus

### Kurzfristig (Stunden bis Tage)

1. In der Fritzbox die Portweiterleitung für 80 und 443 auf die
   andere Matratze umstellen.
2. Fertig. Die Zertifikate liegen dort schon.

### Dauerhaft (matratze02 fällt länger aus)

Die gemeinsamen Namen werden nicht mehr erneuert. Die letzte Kopie
gilt noch bis zu 90 Tage.

1. `matratze.gst…` und `haproxy.gst…` in den host_vars von matratze02
   entfernen und bei matratze03 eintragen.
2. matratze02 im Inventory (`proxmox_gst`) auskommentieren.
3. Playbook laufen lassen und auf matratze03 einmal
   `dehydrated --cron` ausführen (der Handler läuft nur, wenn sich
   `domains.txt` ändert).

## Neue Matratze aufsetzen

Am Beispiel matratze03:

1. DNS: `matratze03.gst.hamburg.adfc.de` als CNAME auf
   `gst.hamburg.adfc.de` anlegen (deSEC). **Ohne diesen Eintrag
   scheitert die Zertifikatsanforderung.**
2. `host_vars/<name>.yml` anlegen: `ansible_host`, SSH-Sprung über
   babelfish, `haproxy_dehydrated_domains`,
   `haproxy_cert_and_key_files`, `haproxy_ssl_sites`.
3. Im Inventory unter `proxmox_gst` eintragen.
4. Bei Neuinstallation: alten Hostkey aus `~/.ssh/known_hosts`
   entfernen und den neuen aus dem LAN gegenprüfen, z. B. von einer
   anderen Matratze mit `ssh-keyscan <ip> | ssh-keygen -lf -`.
5. Den Server im Backend `https_matratze.gst.hamburg.adfc.de` in
   `haproxy_file_extra_content` eintragen.
6. `ansible-playbook playbooks/matratze.yml --diff`
7. Auf der neuen Matratze einmal `dehydrated --cron`, danach auf allen
   Matratzen `/usr/local/share/harpoxy-key-copy/fetch-certs`.

Beim Entfernen einer Matratze:

- Alle host_vars prüfen, die über ihren SSH-Port springen
  (`grep -r "babelfish.spdns.de -p" host_vars`).
- Alte `.pem` in `/etc/haproxy/certs/` entfernen. Sonst liefert
  haproxy unter Umständen ein abgelaufenes Zertifikat mit denselben
  Namen aus.

## SSH-Zugang

Die Matratzen und VMs werden über Portweiterleitungen auf
`babelfish.spdns.de` erreicht (`ansible_ssh_common_args` in den
host_vars):

- Port 825 → matratze02, dient auch als Sprung-Host für matratze03
  und nextcloud-srv.
- Port 824 → war matratze01, derzeit tot.

Fällt matratze02 aus, sind matratze03 und nextcloud-srv per Ansible
nicht mehr erreichbar. Abhilfe: Port 824 in der Fritzbox auf
matratze03 (192.168.123.92) umbiegen.

## Prüfen

```bash
# Welches Zertifikat liefert haproxy von außen aus?
echo | openssl s_client -connect matratze.gst.hamburg.adfc.de:443 \
  -servername matratze.gst.hamburg.adfc.de 2>/dev/null \
  | openssl x509 -noout -enddate -subject

# Gültigkeit aller Zertifikate im haproxy
ansible proxmox_gst -m shell -a 'for f in /etc/haproxy/certs/*.pem; \
  do echo "$f $(openssl x509 -noout -enddate -in $f)"; done'
```

## Mögliche Verbesserung: DNS-01 über deSEC

Mit einer DNS-Prüfung über die deSEC-API könnten beide Matratzen die
gemeinsamen Namen unabhängig voneinander erneuern, und der manuelle
Schritt im Notfall entfiele. Dafür braucht es einen deSEC-Token
(in `adfc-secrets`), einen dehydrated-Hook mit
`CHALLENGETYPE="dns-01"` und eine Anpassung von `fetch-certs`, damit
nicht zwei Zertifikate mit denselben Namen im haproxy liegen.
