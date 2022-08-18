#!/bin/bash

URLBASE=$1

declare -A exemplars=(

["6520336"]="text-contributors-instancecontributor"

)

for key in "${!exemplars[@]}"; do
    curl $URLBASE/$key.marc-pkg.xml > ${exemplars[$key]}.rdf
done