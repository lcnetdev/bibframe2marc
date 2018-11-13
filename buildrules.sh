#!/bin/sh

# Generate a rules.xml file from the xml files in the rules/ directory

if [ "$1" = "" ]; then
  RULES_FILE=rules.xml
else
  RULES_FILE=$1
fi

if [ -r rules/VERSION ]; then
  VERSION=`cat rules/VERSION`
fi

echo "<rules xmlns=\"http://www.loc.gov/bf2marc\">" > $RULES_FILE
if [ "$VERSION" != "" ]; then
  echo "  <version>$VERSION</version>" >> $RULES_FILE
fi

for filename in rules/*.xml; do
  echo "  <file>$filename</file>" >> $RULES_FILE
done

echo "</rules>" >> $RULES_FILE
