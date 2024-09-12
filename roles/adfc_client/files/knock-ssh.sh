#!/bin/bash
/usr/bin/ssh -o "ConnectTimeout 5" -T -i /root/.ssh/knocking-key root@192.168.123.32 >/dev/null 2>&1
