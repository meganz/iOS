import FileProvider
import Foundation
import MEGAPickerFileProviderDomain

/// Stores each folder's snapshot as a file in the app group, rewritten atomically and never locked (`0xdead10cc`).
///
/// The actor serialises updates within the process. Only the extension writes snapshots, and the system normally runs one
/// extension process per domain, so updates from two processes are not guarded against.
public actor FileProviderSnapshotRepository: FileProviderSnapshotRepositoryProtocol {
    /// Updates are only serialised when the whole process uses this instance.
    public static let shared = FileProviderSnapshotRepository(
        directoryURL: FileProviderSyncDirectory.url.appendingPathComponent("Snapshots", isDirectory: true)
    )

    public static var newRepo: FileProviderSnapshotRepository {
        shared
    }

    private static let fileExtension = "snapshot"
    private static let formatVersion: UInt8 = 1
    /// File names keep these as they are and percent-encode the rest; base64 handles only use these.
    private static let fileNameCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))

    private let directoryURL: URL

    init(directoryURL: URL) {
        self.directoryURL = directoryURL
    }

    public func snapshot(of containerIdentifier: NSFileProviderItemIdentifier) throws -> FileProviderSnapshotEntity? {
        let url = fileURL(for: containerIdentifier)
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        // An unreadable file counts as an empty snapshot, so the folder is still compared. A new format has to keep
        // reading this one.
        return Self.decode(try Data(contentsOf: url)) ?? FileProviderSnapshotEntity()
    }

    public func updateSnapshot(
        of containerIdentifier: NSFileProviderItemIdentifier,
        _ update: @Sendable (inout FileProviderSnapshotEntity?) -> Void
    ) throws {
        let original = try snapshot(of: containerIdentifier)
        var snapshot = original
        update(&snapshot)
        guard snapshot != original else {
            return
        }
        guard let snapshot else {
            try removeSnapshot(of: containerIdentifier)
            return
        }
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try Self.encode(snapshot).write(to: fileURL(for: containerIdentifier), options: .atomic)
    }

    public func removeSnapshot(of containerIdentifier: NSFileProviderItemIdentifier) throws {
        do {
            try FileManager.default.removeItem(at: fileURL(for: containerIdentifier))
        } catch CocoaError.fileNoSuchFile {
            return
        }
    }

    public func containerIdentifiers() throws -> [NSFileProviderItemIdentifier] {
        guard FileManager.default.fileExists(atPath: directoryURL.path) else {
            return []
        }
        return try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == Self.fileExtension }
            .compactMap { $0.deletingPathExtension().lastPathComponent.removingPercentEncoding }
            .map { NSFileProviderItemIdentifier($0) }
    }

    // MARK: - Private

    private func fileURL(for containerIdentifier: NSFileProviderItemIdentifier) -> URL {
        let name = containerIdentifier.rawValue.addingPercentEncoding(withAllowedCharacters: Self.fileNameCharacters) ?? containerIdentifier.rawValue
        return directoryURL.appendingPathComponent(name).appendingPathExtension(Self.fileExtension)
    }

    /// A format version byte, then for each child: the identifier's length in one byte, its UTF-8 bytes, and the
    /// version hash in eight little-endian bytes, about 17 bytes per child.
    private static func encode(_ snapshot: FileProviderSnapshotEntity) -> Data {
        var data = Data([formatVersion])
        for (identifier, versionHash) in snapshot.versionHashes {
            let identifierBytes = Data(identifier.rawValue.utf8)
            // Base64 handles are 8 bytes long; a longer identifier is left out and looks new to every comparison.
            guard identifierBytes.count <= Int(UInt8.max) else {
                continue
            }
            data.append(UInt8(identifierBytes.count))
            data.append(identifierBytes)
            withUnsafeBytes(of: versionHash.littleEndian) { data.append(contentsOf: $0) }
        }
        return data
    }

    private static func decode(_ data: Data) -> FileProviderSnapshotEntity? {
        let bytes = [UInt8](data)
        guard bytes.first == formatVersion else {
            return nil
        }
        var versionHashes: [NSFileProviderItemIdentifier: UInt64] = [:]
        var index = 1
        while index < bytes.count {
            let identifierLength = Int(bytes[index])
            let identifierStart = index + 1
            let hashStart = identifierStart + identifierLength
            let end = hashStart + 8
            guard end <= bytes.count, let identifier = String(bytes: bytes[identifierStart..<hashStart], encoding: .utf8) else {
                return nil
            }
            var versionHash: UInt64 = 0
            for (shift, byte) in bytes[hashStart..<end].enumerated() {
                versionHash |= UInt64(byte) << (8 * shift)
            }
            versionHashes[NSFileProviderItemIdentifier(identifier)] = versionHash
            index = end
        }
        return FileProviderSnapshotEntity(versionHashes: versionHashes)
    }
}
