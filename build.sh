#!/usr/bin/env bash
# Builds the npm package into pkg/ and packs it as photocraft-wasm-<version>.tgz in this folder.
# Needs rustup (rust-toolchain.toml picks the compiler and adds the wasm32 target) and Node.js.
set -euo pipefail
cd "$(dirname "$0")"

# wasm-pack fetches the wasm-bindgen CLI that matches Cargo.lock.
npx --yes wasm-pack@0.15.0 build --release --target web --scope madcoons --out-dir pkg

# PhotoCraft's license and notice ship with its compiled code.
cp third-party/photocraft/LICENSE-MIT pkg/LICENSE-PHOTOCRAFT-MIT
cp third-party/photocraft/LICENSE-APACHE pkg/LICENSE-PHOTOCRAFT-APACHE
cp third-party/photocraft/NOTICE pkg/NOTICE-PHOTOCRAFT
jq '.files += ["LICENSE-PHOTOCRAFT-MIT", "LICENSE-PHOTOCRAFT-APACHE", "NOTICE-PHOTOCRAFT"]' pkg/package.json > pkg/package.json.tmp
mv pkg/package.json.tmp pkg/package.json

npm pack ./pkg --pack-destination .
