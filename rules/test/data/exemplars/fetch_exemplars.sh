#!/bin/bash

URLBASE=$1

declare -A exemplars=(

["18344194"]="musicaudio-monograph-contributors-titles-identifiers"
["19537131"]="musicaudio-monograph-hamilton-contributos-subjects-genreforms"
["12060035"]="musicaudio-382s-captures-7xxs"
["21851594"]="notatedmusic-relationships"
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
["20621601"]="text-monograph-classifications-008t"
["1972268"]="text-monograph-classification-manufacture-008s"
["22014581"]="text-monograph-880s-008s"

["16362995"]="text-monograph-uncontrolledsubjects-uncontrollednames"

["21665525"]="text-monograph-series-matching490and830"
["18602501"]="text-monograph-series-germansubjects"
["16998093"]="text-monograph-series-matching490and830-810"
["2971034"]="text-monograph-series-matching490and811"
# 20231121 - cataloger updated and ruined the following for testing purposes.  
# Will keep the 'good' one for now. 
# ["19279034"]="text-monograph-series-unmatched490sand830"   
["22076502"]="text-monograph-series-sole490withIssn"
["4384447"]="text-monograph-series-490paralleltitle-830-contributors"

["20898769"]="text-monograph-obamabecoming-subjects-386s"

["11891684"]="text-serial-microform-007s-relationships"
["11982059"]="cartographic-three007s"
["11511184"]="movingimage-wizard-of-oz"
["21933307"]="nonmusicaudio-one300tomultiple-two007s"
)

for key in "${!exemplars[@]}"; do
    if [[ $URLBASE == *"bibs"* ]]; then
        curl $URLBASE/$key.bibframe_raw.rdf > raw.${exemplars[$key]}.rdf
        curl $URLBASE/$key.decomposed.rdf > ${exemplars[$key]}.rdf
    else
        curl $URLBASE/$key.cbd.rdf > id.${exemplars[$key]}.rdf
    fi
done