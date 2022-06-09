#!/bin/bash

next_release=$1

for lang in {en,zh} ; do
  cp -r content/${lang}/docs/$((next_release-1)).0 content/${lang}/docs/${next_release}.0

  sed -i.bak 's/(Development)/(RC)/' ./content/${lang}/docs/${next_release}.0/_index.md
  sed -i.bak 's/Under construction, development release./Release Candidate./' ./content/${lang}/docs/${next_release}.0/_index.md
  rm -f ./content/${lang}/docs/${next_release}.0/_index.md.bak
done

sed -i.bak 's/current = "'$((next_release-1))'.0"/current = "'$((next_release))'.0"/g' ./config.toml
sed -i.bak 's/next = "'$((next_release))'.0"/next = "'$((next_release+1))'.0"/g' ./config.toml
rm -f ./config.toml.bak
