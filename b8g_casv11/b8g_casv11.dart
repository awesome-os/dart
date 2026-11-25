// Copyright (c) 2026 Awesome-OS Contributors.
// Zero-external-dependency Dart utility for Awesome-OS unified v11 CAS
// addressing and holo-compiler WasmGC / AOT artifact descriptors.

/// Canonical B8G UniversalABI v3 magic (`0x33564742` / `"BGV3"`).
const int b8gAbiMagicV3 = 0x33564742;

/// Default cache-line alignment in bytes for `B8G_ARENA_V1` zero-copy arenas.
const int b8gArenaAlignmentBytes = 64;

/// Supported Dart build output kinds indexed into the unified v11 CAS.
enum CasV11ArtifactKind {
  /// Native Dart AOT snapshot / ELF / PE executable.
  aotSnapshot('aot-snapshot'),

  /// `dart2wasm` WasmGC binary module (`.wasm`).
  wasmGcModule('wasmgc-module'),

  /// Dart Kernel binary intermediate (`.dill`).
  kernelDill('kernel-dill'),

  /// `holo-compiler` content-addressed object pack (`.b8p`).
  b8pPack('b8p-pack');

  const CasV11ArtifactKind(this.wireName);

  final String wireName;

  static CasV11ArtifactKind fromWireName(String value) {
    for (final kind in values) {
      if (kind.wireName == value) {
        return kind;
      }
    }
    throw ArgumentError.value(value, 'value', 'Unknown CasV11ArtifactKind');
  }
}

final RegExp _sha512HexPattern = RegExp(r'^[0-9a-fA-F]{128}$');

/// Resolves the canonical v11 CAS content-addressed blob path for a SHA-512
/// digest: `<casRoot>/files/<hh>/<rest126>[-exec]`.
String v11BlobPath(
  String casRoot,
  String sha512Hex, {
  bool executable = false,
}) {
  final normalizedHash = sha512Hex.trim().toLowerCase();
  if (!_sha512HexPattern.hasMatch(normalizedHash)) {
    throw ArgumentError.value(
      sha512Hex,
      'sha512Hex',
      'Expected a 128-character hexadecimal SHA-512 digest',
    );
  }

  var root = casRoot.trim().replaceAll('\\', '/');
  while (root.length > 1 && root.endsWith('/')) {
    root = root.substring(0, root.length - 1);
  }
  if (root.isEmpty) {
    throw ArgumentError.value(casRoot, 'casRoot', 'CAS root must not be empty');
  }

  final shard = normalizedHash.substring(0, 2);
  final leaf = normalizedHash.substring(2);
  final suffix = executable ? '-exec' : '';
  return '$root/files/$shard/$leaf$suffix';
}

/// Immutable descriptor for a Dart AOT or WasmGC artifact stored in the
/// Awesome-OS unified v11 CAS and consumed by `holo-compiler`.
final class CasV11ArtifactDescriptor {
  const CasV11ArtifactDescriptor({
    required this.kind,
    required this.targetTriple,
    required this.sha512Hex,
    required this.byteLength,
    this.executable = false,
    this.abiMagic = b8gAbiMagicV3,
    this.arenaAlignment = b8gArenaAlignmentBytes,
    this.entryPoint,
  });

  /// Artifact classification (AOT snapshot, WasmGC module, `.dill`, or `.b8p`).
  final CasV11ArtifactKind kind;

  /// Target triple (e.g. `wasm32-wasmgc`, `x86_64-windows-msvc`, `x86_64-linux-musl`).
  final String targetTriple;

  /// 128-character hexadecimal SHA-512 content digest.
  final String sha512Hex;

  /// Exact uncompressed payload length in bytes.
  final int byteLength;

  /// Whether the CAS blob carries executable permissions (`-exec` suffix).
  final bool executable;

  /// B8G ABI magic tag; defaults to [b8gAbiMagicV3].
  final int abiMagic;

  /// Required `B8G_ARENA_V1` memory alignment in bytes; defaults to 64.
  final int arenaAlignment;

  /// Optional exported entry symbol or Dart library URI.
  final String? entryPoint;

  /// Resolves the blob path for this artifact under [casRoot].
  String blobPath(String casRoot) =>
      v11BlobPath(casRoot, sha512Hex, executable: executable);

  /// Serializes this descriptor to a deterministic JSON-compatible map.
  Map<String, Object?> toJson() => <String, Object?>{
        'abiMagic': abiMagic,
        'arenaAlignment': arenaAlignment,
        'byteLength': byteLength,
        if (entryPoint != null) 'entryPoint': entryPoint,
        'executable': executable,
        'kind': kind.wireName,
        'sha512Hex': sha512Hex.toLowerCase(),
        'targetTriple': targetTriple,
      };

  /// Reconstructs a [CasV11ArtifactDescriptor] from a decoded JSON map.
  factory CasV11ArtifactDescriptor.fromJson(Map<String, Object?> json) {
    final kindRaw = json['kind'];
    final targetTriple = json['targetTriple'];
    final sha512Hex = json['sha512Hex'];
    final byteLength = json['byteLength'];

    if (kindRaw is! String ||
        targetTriple is! String ||
        sha512Hex is! String ||
        byteLength is! int) {
      throw const FormatException(
        'Invalid CasV11ArtifactDescriptor JSON payload',
      );
    }

    return CasV11ArtifactDescriptor(
      kind: CasV11ArtifactKind.fromWireName(kindRaw),
      targetTriple: targetTriple,
      sha512Hex: sha512Hex,
      byteLength: byteLength,
      executable: (json['executable'] as bool?) ?? false,
      abiMagic: (json['abiMagic'] as int?) ?? b8gAbiMagicV3,
      arenaAlignment: (json['arenaAlignment'] as int?) ?? b8gArenaAlignmentBytes,
      entryPoint: json['entryPoint'] as String?,
    );
  }
}
