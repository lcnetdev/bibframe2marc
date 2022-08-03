#!/bin/bash

URLBASE=$1

declare -A exemplars=(

["18344194"]="musicaudio-monograph-contributors-titles-identifiers"
["20779915"]="notatedmusic-monograph-genreforms"
["21340497"]="notatedmusic-monograph-subjects-paralleltitle-contributors-genreforms"
["10496140"]="notatedmusic-manuscript-monograph-01"
["20525980"]="notatedmusic-manuscript-monograph-02"

)

for key in "${!exemplars[@]}"; do
    curl $URLBASE/$key.bibframe_raw.rdf > ${exemplars[$key]}.rdf
done