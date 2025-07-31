#!/bin/bash
echo 'Unattended-Upgrade::Allowed-Origins:: "origin=*";' >/etc/apt/apt.conf.d/52all_updates
/usr/bin/unattended-upgrades
rm /etc/apt/apt.conf.d/52all_updates
