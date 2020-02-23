#!/bin/bash

# Siehe ADFC Ansible

#date >>/tmp/pdfprint
#echo $@ >>/tmp/pdfprint
#export >>/tmp/pdfprint

lp -d bizhub_C220 $1
rm $1
