#!/usr/bin/env bash
# Creates GitHub release <tag> with the .tgz that build.sh packed into this folder. Needs GH_TOKEN.
set -euo pipefail
cd "$(dirname "$0")"

tag="$1"
file="$(ls ./*.tgz)"
file="${file#./}"
upstream="$(sed -n 's/^photocraft-engine = .*tag = "\(v[^"]*\)".*/\1/p' Cargo.toml)"
url="https://github.com/${GITHUB_REPOSITORY:-madcoons/artcraft-wasm}/releases/download/${tag}/${file}"

gh release create "$tag" "$file" --title "$tag" --notes-file - <<EOF
The PhotoCraft engine ${upstream} compiled to WebAssembly.

Install it in package.json:

\`\`\`json
"@madcoons/photocraft-wasm": "${url}"
\`\`\`
EOF
