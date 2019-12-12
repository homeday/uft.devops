#!/bin/bash

echo "Indexing ..."
date

opengrok-indexer \
    -J=-Djava.util.logging.config.file=/opengrok/etc/logging.properties \
    -a /opengrok/dist/lib/opengrok.jar -- \
    -c /usr/local/bin/ctags \
    -s /opengrok/src -d /opengrok/data -H -P -S -G \
    -W /opengrok/etc/configuration.xml -U http://localhost:8080/source

echo
date
echo "Done!"