# artcraft-wasm

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
  "@madcoons/photocraft-wasm": "https://github.com/madcoons/artcraft-wasm/releases/download/v0.11.101/madcoons-photocraft-wasm-0.11.101.tgz"
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
number: PhotoCraft 0.11.1 is `0.11.101`, and a packaging-only fix of it is `0.11.102`.

## Building

You need [rustup](https://rustup.rs) and Node.js. `rust-toolchain.toml` picks the compiler and adds the wasm
target.

```sh
./build.sh   # writes pkg/ and madcoons-photocraft-wasm-<version>.tgz
```

## Releasing

1. Set `version` in `Cargo.toml`. For a new PhotoCraft version, also change both `tag`s and run
   `cargo update -p photocraft-engine`.
2. Merge to `main`.
3. Push the tag: `git tag v0.11.101 && git push origin v0.11.101`.

`release.yml` checks that the tag matches `Cargo.toml`, builds the package and creates the GitHub release with
the `.tgz` attached. Turn on immutable releases in the repository settings, so a published file can't be
replaced under a lockfile that pins its checksum.

## License

This repository's code is MIT, see [LICENSE](LICENSE). The package contains compiled PhotoCraft code, which is
MIT OR Apache-2.0; its license and notice are in [third-party/photocraft](third-party/photocraft) and ship in the
package as `LICENSE-PHOTOCRAFT-MIT`, `LICENSE-PHOTOCRAFT-APACHE` and `NOTICE-PHOTOCRAFT`.
