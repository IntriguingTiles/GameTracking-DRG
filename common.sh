#!/bin/bash

. ./depot-key.sh

download_depot_with_manifest () {
    echo "Downloading $1..."
    until dotnet tools/DD/DepotDownloader.dll -app 548430 -depot 548431 -depot-key $DEPOT_KEY -manifest $1 -manifest-only -dir work
    do
        echo "Retrying..."
    done
    until dotnet tools/DD/DepotDownloader.dll -app 548430 -depot 548431 -depot-key $DEPOT_KEY -manifest $1 -filelist downloadlist.txt -dir work
    do
        echo "Retrying..."
    done
}

download_depot () {
    echo "Downloading latest depot..."
    until dotnet tools/DD/DepotDownloader.dll -app 548430 -depot 548431 -depot-key $DEPOT_KEY -manifest-only -dir work
    do
        echo "Retrying..."
    done
    until dotnet tools/DD/DepotDownloader.dll -app 548430 -depot 548431 -depot-key $DEPOT_KEY -filelist downloadlist.txt -dir work
    do
        echo "Retrying..."
    done
}

mine () {
    # dump strings
    strings work/FSD/Binaries/Win64/FSD-Win64-Shipping.exe >> work/FSD/Binaries/Win64/FSD-Win64-Shipping.txt
    # some builds of DRG have a slightly different exe name
    strings work/FSD/Binaries/Win64/FSD.exe >> work/FSD/Binaries/Win64/FSD-Win64-Shipping.txt
    # dump pak info
    dotnet tools/UE4DMT/PakDumper.dll work/FSD/Content/Paks/FSD-WindowsNoEditor.pak
    # extract stuff from the pak
    tools/QBMS/quickbms -f "*.ini;*.txt;*.locres;*.uproject;*.upluginmanifest" tools/QBMS/unreal_tournament_4.bms work/FSD/Content/Paks/FSD-WindowsNoEditor.pak work
    # dump localization
    find work -name '*.locres' -exec dotnet tools/UE4DMT/LocresDumper.dll {} \;
    
    # prepare to commit to git
    mv work/manifest_* work/manifest.txt
    # i have no idea what i'm doing
    DATE=$(awk '{split($0,a," / "); print a[3]}' work/manifest.txt | tr -d '\n')
    rm -r work/.DepotDownloader
    rm -rf repo/FSD
    rm -rf repo/Engine
    mv work/* repo/
    make_commit "$(date -d"$DATE" +%s) +0000"
}

make_commit () {
    # stolen from steamdb's gametracking :^)
    cd repo
    git add -A
    MESSAGE="$(git status --porcelain | wc -l) files | $(git status --porcelain | sed '{:q;N;s/\n/, /g;t q}' | sed 's/^ *//g' | cut -c 1-1024)"
    export GIT_COMMITTER_DATE="$1"
    export GIT_AUTHOR_DATE="$1"
    git commit -a -m "$MESSAGE"
    git push
    cd ..
}