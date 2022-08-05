#!/bin/bash

URLBASE=$1

declare -A exemplars=(

["18344194"]="musicaudio-monograph-contributors-titles-identifiers"
["20779915"]="notatedmusic-monograph-genreforms"
["21340497"]="notatedmusic-monograph-subjects-paralleltitle-contributors-genreforms"
["10496140"]="notatedmusic-manuscript-monograph-01"
["20525980"]="notatedmusic-manuscript-monograph-02"

["21009588"]="musicaudio-monograph-varianttitles-subjects-008p"
["11457859"]="text-serial-SUBJECTS-relationships-008c"
["11393548"]="text-serial-008d"
["14437118"]="stillimage-collection-pnp-008i"
["12280298"]="musicaudio-monograph-contributions-008m"
["22724623"]="stillimage-monograph-subjects-pnp-008q"
)

for key in "${!exemplars[@]}"; do
    curl $URLBASE/$key.bibframe_raw.rdf > ${exemplars[$key]}.rdf
done