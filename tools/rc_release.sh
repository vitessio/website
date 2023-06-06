#!/bin/bash

set -euo pipefail

next_release=${1:-""}

if [[ -z ${next_release} ]]; then
  echo "No next release version specifed."
  echo "Usage example: ${0} \"18\" (to add 18.0 docs as part of v17.0 rc release)" 
  exit 1
fi

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
