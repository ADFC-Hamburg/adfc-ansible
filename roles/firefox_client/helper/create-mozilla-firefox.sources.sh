#!/bin/bash

# Key für sources-Datei formatieren
echo "Types: deb"
echo "URIs: https://packages.mozilla.org/apt"
echo "Suites: mozilla"
echo "Components: main"
echo "Signed-By:"
wget -qO- https://packages.mozilla.org/apt/repo-signing-key.gpg | sed 's/^/ /'
