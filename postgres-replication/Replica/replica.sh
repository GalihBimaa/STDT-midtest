#!/bin/bash
set -e

rm -rf /var/lib/postgresql/data/*

pg_basebackup -h primary -D /var/lib/postgresql/data -U replicator -Fp -Xs -P -R
