#!/usr/bin/env bash
# Creates GitHub release <tag> of upstream PhotoCraft <upstream-version> at packaging <revision> with the .tgz
# that build.sh packed into this folder. The tag is made at <commit>, the commit the package was built from
# with bump.sh applied, so a release needs no commit of its own. Needs GH_TOKEN.
set -euo pipefail
cd "$(dirname "$0")"

tag="$1"
upstream="$2"
revision="$3"
commit="$4"
file="$(ls ./*.tgz)"
file="${file#./}"
url="https://github.com/${GITHUB_REPOSITORY:-madcoons/artcraft-wasm}/releases/download/${tag}/${file}"

gh release create "$tag" "$file" --target "$commit" --title "$tag" --notes-file - <<EOF
The PhotoCraft engine v${upstream} compiled to WebAssembly.

Install it in package.json:

\`\`\`json
"@madcoons/photocraft-wasm": "${url}"
\`\`\`

Built from \`${commit}\` with \`photocraft/bump.sh ${upstream} ${revision}\` applied.
EOF
