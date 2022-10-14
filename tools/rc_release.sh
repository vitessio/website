#!/bin/bash

next_release=$1

for lang in {en,zh} ; do
  cp -r content/${lang}/docs/$((next_release-1)).0 content/${lang}/docs/${next_release}.0

  sed -E -r -i.bak 's/weight: [0-9]+/weight: '$((100-next_release))'/' ./content/${lang}/docs/$((next_release)).0/_index.md
  sed -i.bak 's/'$((next_release-1))'.0/'$((next_release))'.0/' ./content/${lang}/docs/$((next_release)).0/_index.md
  sed -i.bak 's/(Development)/(RC)/' ./content/${lang}/docs/$((next_release-1)).0/_index.md
  sed -i.bak 's/Under construction, development release./Release Candidate./' ./content/${lang}/docs/$((next_release-1)).0/_index.md
  rm -f ./content/${lang}/docs/$((next_release)).0/_index.md.bak
  rm -f ./content/${lang}/docs/$((next_release-1)).0/_index.md.bak
done

sed -i.bak 's/current = "'$((next_release-2))'.0"/current = "'$((next_release-1))'.0"/' ./config.toml
sed -i.bak 's/next = "'$((next_release-1))'.0"/next = "'$((next_release))'.0"/' ./config.toml
rm -f ./config.toml.bak
