#!/bin/bash
. ./common.sh

while read -r LINE
do
    rm -rf work
    download_depot_with_manifest $LINE
    mine
done < "manifests.txt"