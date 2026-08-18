#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type


def sanitize_source_name(path):
    """Nachbau von sanitize_source_name() aus docker-borg-backup's backup.sh
    (und roles/borg_server/templates/adfc-borg-docker.j2:borg_backup_plain) -
    muss exakt gleich bleiben, sonst passen die Mountnamen nicht mehr."""
    name = path
    if name.startswith('/'):
        name = name[1:]
    if name.endswith('/'):
        name = name[:-1]
    name = name.replace('/', '-')
    return name or 'root'


def docker_source_excludes(exclude_dirs, source_dirs):
    """Remapped borg_save_exclude_dirs-Eintraege auf die /source/<name>-Mounts,
    die docker-borg-backup (compose- wie plain-docker-Pfad) fuer jeden Eintrag
    aus borg_save_path anlegt. Absolute Pfade (fuehrender "/") werden auf den
    laengsten passenden Quellordner umgeschrieben; alles andere (Glob-Muster
    wie "*/ImapMail", die ohnehin unverankert matchen) bleibt unveraendert.
    Nicht-absolute Pfade, die zu keinem Quellordner passen, bleiben ebenfalls
    unveraendert (matchen dann nichts - wie vorher schon bei adfc-borg-pyenv,
    falls der Eintrag dort schon vestigial war)."""
    # rstrip('/') macht aus dem Wurzelverzeichnis "/" einen leeren String -
    # damit matcht "startswith(source_dir + '/')" unten fuer die Wurzel jeden
    # absoluten Pfad (source_dir + '/' wird zu '/'), und sanitize_source_name
    # liefert fuer '' genau wie fuer '/' "root". Nach Laenge absteigend
    # sortiert, damit spezifischere Quellordner vor der Wurzel greifen.
    dirs = sorted({d.rstrip('/') for d in source_dirs}, key=len, reverse=True)
    result = []
    for exclude in exclude_dirs or []:
        mapped = exclude
        if exclude.startswith('/'):
            for source_dir in dirs:
                if exclude == source_dir or exclude.startswith(source_dir + '/'):
                    mapped = '/source/' + sanitize_source_name(source_dir) + exclude[len(source_dir):]
                    break
        result.append(mapped)
    return result


class FilterModule(object):
    def filters(self):
        return {
            'docker_source_excludes': docker_source_excludes,
        }
