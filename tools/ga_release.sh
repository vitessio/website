#!/bin/bash

ga_release=$1

for lang in {en,zh} ; do
  sed -i.bak 's/(RC)/(Stable)/' ./content/${lang}/docs/${ga_release}.0/_index.md
  sed -i.bak 's/Release Candidate./Latest stable release./' ./content/${lang}/docs/${ga_release}.0/_index.md
  sed -i.bak 's/Release candidate./Latest stable release./' ./content/${lang}/docs/${ga_release}.0/_index.md
  sed -i.bak 's/Latest stable release.//' ./content/${lang}/docs/$((ga_release-1)).0/_index.md
  sed -i.bak '/^$/d' ./content/${lang}/docs/${ga_release}.0/_index.md
  rm -f ./content/${lang}/docs/${ga_release}.0/_index.md.bak
  rm -f ./content/${lang}/docs/$((ga_release-1)).0/_index.md.bak
done
