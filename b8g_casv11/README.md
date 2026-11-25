# Awesome-OS Dart `b8g_casv11` Integration

Zero-external-dependency bridge connecting the Awesome-OS hard-fork of the Dart SDK (`awesome-os/dart`) to the unified **v11 Content-Addressable Store (CAS)** and **`holo-compiler`** WasmGC / AOT build pipeline.

## Key Invariants

- **ABI Magic:** `b8gAbiMagicV3 = 0x33564742` (`B8G_ABI_MAGIC_V3`), matching `sectium-cloud-control-plane` and `b8g-runtime`.
- **Arena Alignment:** `64`-byte aligned `B8G_ARENA_V1` buffers for zero-copy handoff between Dart AOT / WasmGC modules and host runtimes.
- **v11 CAS Layout:** `v11BlobPath(casRoot, sha512Hex, executable: ...)` maps 128-character SHA-512 digests to `<casRoot>/files/<hh>/<rest126>[-exec]`.

## `holo-compiler` WasmGC & AOT Intersection

`CasV11ArtifactDescriptor` records content-addressed metadata for:

| `CasV11ArtifactKind` | Wire Name | Purpose |
| :--- | :--- | :--- |
| `aotSnapshot` | `aot-snapshot` | Native Dart AOT snapshots and PE/ELF executables |
| `wasmGcModule` | `wasmgc-module` | `dart2wasm` WasmGC modules (`wasm32-wasmgc`) |
| `kernelDill` | `kernel-dill` | Frontend Kernel `.dill` intermediates |
| `b8pPack` | `b8p-pack` | `holo-compiler` `.b8p` CAS object packs |

Descriptors serialize deterministically via `toJson()` / `fromJson()` for `holo-compiler` build manifests and `RollingReleaseManifest` snapshots without pulling in any third-party Pub dependencies.
