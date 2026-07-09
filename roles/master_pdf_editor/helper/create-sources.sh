#!/bin/bash

# Key für sources-Datei formatieren
echo "Types: deb"
echo "URIs: http://repo.code-industry.net/deb"
echo "Suites: stable"
echo "Components: main"
echo "Signed-By:"
wget -qO- http://repo.code-industry.net/deb/pubmpekey.asc  | sed 's/^/ /'
