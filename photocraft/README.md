# @madcoons/photocraft-wasm

The [PhotoCraft](https://github.com/storytold/photocraft) image engine compiled to WebAssembly, as the npm
package `@madcoons/photocraft-wasm`: open a file from its bytes, run any engine command, and read the
composite, without a server.

> **Unofficial.** This is independent packaging of PhotoCraft's engine; it isn't made or endorsed by the
> PhotoCraft authors.

## Install

Each [release](https://github.com/madcoons/artcraft-wasm/releases) attaches the package as a `.tgz`. Install it
by URL:

```json
"dependencies": {
  "@madcoons/photocraft-wasm": "https://github.com/madcoons/artcraft-wasm/releases/download/photocraft-v0.11.101/madcoons-photocraft-wasm-0.11.101.tgz"
}
```

The wasm is about 23 MB (9 MB as a gzip download). It loads only when you call `init()`, so keep it out of your
main bundle by using it from a worker or a lazily loaded module.

**Vite:** exclude the package from dependency pre-bundling, or the dev server can't find the `.wasm`:

```js
optimizeDeps: { exclude: ["@madcoons/photocraft-wasm"] }
```

## API

```ts
import init, { Editor } from "@madcoons/photocraft-wasm";

const { memory } = await init(); // resolves to the wasm exports
const editor = new Editor();

editor.openBytesAs("mockup.psd", new Uint8Array(await file.arrayBuffer()));
const doc = editor.execute("document.inspect", {}); // { width, height, layers, ... }
editor.execute("image.imageSize", { percent: 50 });
editor.execute("layer.fill.solidColor.set", { layer: 42, color: "#ff0000" });

const { width, height } = editor.render();
const pixels = new Uint8ClampedArray(memory.buffer, editor.framePtr(), editor.frameLen());
ctx.putImageData(new ImageData(pixels, width, height), 0, 0);
```

| Method | What it does |
|---|---|
| `openBytesAs(name, bytes, ext?)` | Opens a file and makes it the active document. Decoded by `name`'s extension, or by `ext`. Returns `{ document, color, warnings }`. |
| `execute(id, params)` | Runs an engine command by id with JSON params and returns its JSON result. The commands are PhotoCraft's (`photocraft-cli` lists them). |
| `render()` | Composites the active document into the editor's frame, straight RGBA8. Returns `{ width, height }`. |
| `framePtr()`, `frameLen()` | Where that frame is in wasm memory. |
| `free()` | Releases the editor and its documents. |

**Reading the frame without a copy:** the view on `memory.buffer` is valid until the next call into the
editor. Make it again after every call: when wasm memory grows, its old buffer is detached and every view on it
reads as empty.

### Things to know

- **Synchronous and single-threaded.** Every call blocks until it's done. Run the editor in a Web Worker
  (with an `OffscreenCanvas` it can draw straight to the page) so a composite never freezes the UI.
- **sRGB only.** `render()` returns the document's values unconverted, which is right for RGB documents in
  sRGB. CMYK or other colour profiles come out wrong.
- **No filesystem.** Commands that take a path (`file.open`, `file.save` and the like) fail; open files with
  `openBytesAs`.
- **Render cost grows with pixels.** A render composites the whole document. Shrink large files with
  `image.imageSize` first when you only need a preview.

## Versions

A package version is the upstream PhotoCraft version with a two-digit packaging revision appended to the patch
number (`photocraft/package-version.sh`): at revision 1, PhotoCraft 0.11.1 is `0.11.101` and 0.14.0 is `0.14.1`.
The revision is ours, not upstream's: it counts packagings of the same PhotoCraft code, and lives in
`photocraft/REVISION` (1-99), the only place it's set.

## Building

You need [rustup](https://rustup.rs) and Node.js. `rust-toolchain.toml` picks the compiler and adds the wasm
target.

```sh
photocraft/build.sh   # writes photocraft/pkg/ and photocraft/madcoons-photocraft-wasm-0.0.0.tgz
```

`Cargo.toml`'s `version` is a `0.0.0` placeholder, so a local build is never mistaken for a release. To build a
release locally, run `photocraft/bump.sh 0.14.0` first (and don't commit what it changes).

## Releasing

**Releases need no commits.** Every day `photocraft-release.yml` lists the upstream stable releases from 0.11.1
on that are at least 24 hours old and have no `photocraft-v<version>` release here yet
(`photocraft/missing-releases.sh`). For each, it checks out `main`, applies `photocraft/bump.sh <version>` to the
checkout, builds, and creates the release with the `.tgz` attached; the tag is made at that `main` commit
(`photocraft/release.sh`). `main` keeps whatever PhotoCraft version `Cargo.toml` names; that's only what CI and
local builds use.

If a version fails to build, it isn't released and the next day's run tries it again; fix the code on `main` and
it goes out. Run the workflow by hand from the Actions tab to release now, optionally for one version without
the 24-hour wait.

**A packaging fix** (the wrapper, the build, the licence files): fix it on `main` and raise `photocraft/REVISION`
in the same change. The next run releases every version from 0.11.1 again at the new revision, e.g. `0.14.0`
at revision 2 as `photocraft-v0.14.2`, because none of them has a release at that revision yet.

Turn on immutable releases in the repository settings, so a published file can't be replaced under a lockfile
that pins its checksum.

## License

This package's own code is MIT (the repository's `LICENSE`). It contains compiled PhotoCraft code, which is MIT
OR Apache-2.0; its license and notice are in `photocraft/third-party/` and ship in the package as
`LICENSE-PHOTOCRAFT-MIT`, `LICENSE-PHOTOCRAFT-APACHE` and `NOTICE-PHOTOCRAFT`.
