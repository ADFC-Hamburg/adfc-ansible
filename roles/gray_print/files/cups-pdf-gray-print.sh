#!/bin/bash

# Siehe ADFC Ansible

#date >>/tmp/pdfprint
#echo $@ >>/tmp/pdfprint
#export >>/tmp/pdfprint

lp -o InputSlot=Tray1 -d bizhub_C220 $1 >/tmp/pdfprint 2>&1
rm $1
