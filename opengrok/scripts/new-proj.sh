#!/bin/bash

org="$1"
proj="$2"

if [ -z "$org" -o -z "$proj" ]; then
    echo "Missing one or more arguments!"
    echo "usage: new-proj.sh <org> <proj>"
    exit 2
fi

repo="$proj"
br1=master
br2=UFT_14_53_SP_Patches
br3=UFT_14_03_SP_Patches

# prepare source
/opengrok/scripts/prep-src.sh "$org" "$repo" "$br1"
/opengrok/scripts/prep-src.sh "$org" "$repo" "$br2"
/opengrok/scripts/prep-src.sh "$org" "$repo" "$br3"

# indexing
echo "Indexing (first time) ..."
opengrok-indexer \
    -J=-Djava.util.logging.config.file=/opengrok/etc/logging.properties \
    -a /opengrok/dist/lib/opengrok.jar -- \
    -c /usr/local/bin/ctags \
    -s /opengrok/src -d /opengrok/data -H -P -S -G \
    -W /opengrok/etc/configuration.xml -U http://localhost:8080/source

# add project
opengrok-projadm -b /opengrok -a "$proj"

# indexing again
echo "Reindexing ..."
opengrok-indexer \
    -J=-Djava.util.logging.config.file=/opengrok/etc/logging.properties \
    -a /opengrok/dist/lib/opengrok.jar -- \
    -c /usr/local/bin/ctags \
    -s /opengrok/src -d /opengrok/data -H -P -S -G \
    -W /opengrok/etc/configuration.xml -U http://localhost:8080/source

# save changes to configuration.xml
opengrok-projadm -b /opengrok -r
