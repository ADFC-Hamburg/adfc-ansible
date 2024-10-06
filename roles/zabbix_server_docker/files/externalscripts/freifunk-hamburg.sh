#!/bin/sh
curl --silent --max-time 3 http://[$1]/cgi-bin/dyn/statistics 2>/dev/null | sed 's/^data://g' | tr -d "[:space:]"
exit 0
