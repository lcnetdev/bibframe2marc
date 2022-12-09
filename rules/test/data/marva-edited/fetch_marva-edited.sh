#!/bin/bash

URLBASE=$1

declare -A exemplars=(

["6520336"]="text-contributors-instancecontributor"
["22818936"]="text-contributors-relationship"
["20178796"]="musicaudio-mono-relationships"
["10941364"]="text-serial-issues-008-subjects"
["20952712"]="text-monograph-issues-008-subjects"
["9078040"]="text-serial-issues-008"

)

for key in "${!exemplars[@]}"; do
    if [[ $URLBASE == *"8230"* ]]; then
        curl $URLBASE/$key.marc-pkg.xml > bfdb.${exemplars[$key]}.rdf
    else
        curl $URLBASE/$key.cbd.rdf > id.${exemplars[$key]}.rdf
    fi
done