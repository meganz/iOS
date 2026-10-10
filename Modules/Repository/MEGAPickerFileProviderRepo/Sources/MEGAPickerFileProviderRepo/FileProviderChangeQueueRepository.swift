import FileProvider
import Foundation
import MEGAPickerFileProviderDomain

/// Stores the change queue in the app group as append-only text files, one `<identifier> <folder identifier>` line
/// per change.
///
/// A full file is followed by a new generation and the one before it is deleted, so at most two are kept. Files are
/// appended to with `O_APPEND` and never locked (`0xdead10cc`), so appends from two processes never overlap.
public actor FileProviderChangeQueueRepository: FileProviderChangeQueueRepositoryProtocol {
    /// Appends are only serialised when the whole process uses this instance.
    public static let shared = FileProviderChangeQueueRepository(directoryURL: FileProviderSyncDirectory.url)

    public static var newRepo: FileProviderChangeQueueRepository {
        shared
    }

    private static let queueFilePrefix = "queue-"
    private static let newline = UInt8(ascii: "\n")

    private let directoryURL: URL
    private let maxFileSize: Int

    /// - Parameter maxFileSize: The size from which the next append starts a new generation; 512KB is about 20,000
    ///   changes.
    init(directoryURL: URL, maxFileSize: Int = 512 * 1024) {
        self.directoryURL = directoryURL
        self.maxFileSize = maxFileSize
    }

    public func append(_ changes: [FileProviderChangeEntity]) throws {
        guard !changes.isEmpty else {
            return
        }
        _ = try storeID()

        var generation = try currentGeneration()
        if fileSize(of: generation) >= maxFileSize {
            try removeFile(at: queueFileURL(for: generation - 1))
            generation += 1
        }

        var data = Data()
        for change in changes {
            data.append(Data("\(change.identifier.rawValue) \(change.folderIdentifier.rawValue)\n".utf8))
        }
        let fileHandle = try Self.makeAppendingFileHandle(for: queueFileURL(for: generation))
        defer { try? fileHandle.close() }
        let end = try fileHandle.seekToEnd()
        if end > 0 {
            // A line cut short by a crash must not run into the first appended one.
            try fileHandle.seek(toOffset: end - 1)
            if try fileHandle.read(upToCount: 1) != Data([Self.newline]) {
                data.insert(Self.newline, at: 0)
            }
        }
        // `O_APPEND` puts the data at the end of the file whatever the offset is.
        try fileHandle.write(contentsOf: data)
    }

    public func currentAnchor() throws -> FileProviderChangeAnchorEntity {
        let generation = try currentGeneration()
        return FileProviderChangeAnchorEntity(storeID: try storeID(), generation: generation, offset: try completeLinesLength(of: generation))
    }

    public func changes(since anchor: FileProviderChangeAnchorEntity, limit: Int) throws -> FileProviderChangeBatchEntity {
        let latestGeneration = try currentGeneration()
        let currentStoreID = try storeID()
        guard anchor.storeID == currentStoreID,
              anchor.generation == latestGeneration || anchor.generation == latestGeneration - 1 else {
            throw FileProviderChangeQueueErrorEntity.anchorExpired
        }

        var changes: [FileProviderChangeEntity] = []
        var generation = anchor.generation
        var offset = anchor.offset
        var hasMore = false
        while true {
            let url = queueFileURL(for: generation)
            var bytes: [UInt8] = []
            if FileManager.default.fileExists(atPath: url.path) {
                bytes = Array(try Data(contentsOf: url))
            } else if generation < latestGeneration {
                throw FileProviderChangeQueueErrorEntity.anchorExpired
            }
            // Every anchor handed out is at the start of a line.
            guard offset >= 0, offset <= bytes.count, offset == 0 || bytes[offset - 1] == Self.newline else {
                throw FileProviderChangeQueueErrorEntity.anchorExpired
            }
            // Only lines that end with a newline are read: the last one may still be being written.
            while changes.count < limit, let lineEnd = bytes[offset...].firstIndex(of: Self.newline) {
                if let change = Self.makeChange(fromLine: bytes[offset..<lineEnd]) {
                    changes.append(change)
                }
                offset = lineEnd + 1
            }
            if bytes[offset...].contains(Self.newline) {
                hasMore = true
                break
            }
            guard generation < latestGeneration else {
                break
            }
            // Moving on keeps the anchor valid when this generation is deleted.
            generation += 1
            offset = 0
            if changes.count == limit {
                hasMore = true
                break
            }
        }
        return FileProviderChangeBatchEntity(
            changes: changes,
            nextAnchor: FileProviderChangeAnchorEntity(storeID: anchor.storeID, generation: generation, offset: offset),
            hasMore: hasMore
        )
    }

    // MARK: - Private

    private var storeIDFileURL: URL {
        directoryURL.appendingPathComponent("store-id")
    }

    private func queueFileURL(for generation: Int) -> URL {
        directoryURL.appendingPathComponent("\(Self.queueFilePrefix)\(generation)")
    }

    /// The storage's identifier, created with the storage. A new identifier expires every anchor, which makes the
    /// system enumerate the whole working set again, so it is only replaced when it is damaged.
    private func storeID() throws -> UUID {
        if FileManager.default.fileExists(atPath: storeIDFileURL.path) {
            if let storeID = UUID(uuidString: String(decoding: try Data(contentsOf: storeIDFileURL), as: UTF8.self)) {
                return storeID
            }
            return try writeNewStoreID(options: .atomic)
        }
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        do {
            return try writeNewStoreID(options: .withoutOverwriting)
        } catch CocoaError.fileWriteFileExists {
            // Another process created it first.
            return try storeID()
        }
    }

    private func writeNewStoreID(options: Data.WritingOptions) throws -> UUID {
        let storeID = UUID()
        try Data(storeID.uuidString.utf8).write(to: storeIDFileURL, options: options)
        return storeID
    }

    /// The highest generation on disk, or 0 before the first append.
    private func currentGeneration() throws -> Int {
        guard FileManager.default.fileExists(atPath: directoryURL.path) else {
            return 0
        }
        return try FileManager.default.contentsOfDirectory(atPath: directoryURL.path)
            .compactMap { $0.hasPrefix(Self.queueFilePrefix) ? Int($0.dropFirst(Self.queueFilePrefix.count)) : nil }
            .max() ?? 0
    }

    private func fileSize(of generation: Int) -> Int {
        let attributes = try? FileManager.default.attributesOfItem(atPath: queueFileURL(for: generation).path)
        return (attributes?[.size] as? NSNumber)?.intValue ?? 0
    }

    /// The length of the generation's file up to and including its last newline.
    private func completeLinesLength(of generation: Int) throws -> Int {
        let url = queueFileURL(for: generation)
        guard FileManager.default.fileExists(atPath: url.path) else {
            return 0
        }
        let data = try Data(contentsOf: url)
        return data.lastIndex(of: Self.newline).map { $0 - data.startIndex + 1 } ?? 0
    }

    private func removeFile(at url: URL) throws {
        do {
            try FileManager.default.removeItem(at: url)
        } catch CocoaError.fileNoSuchFile {
            // There was no such generation yet, or another process removed it first.
            return
        }
    }

    /// Opens the file for reading and appending, creating it when there is none.
    private static func makeAppendingFileHandle(for url: URL) throws -> FileHandle {
        let fileDescriptor = open(url.path, O_RDWR | O_CREAT | O_APPEND, 0o644)
        guard fileDescriptor >= 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
        return FileHandle(fileDescriptor: fileDescriptor, closeOnDealloc: true)
    }

    private static func makeChange(fromLine line: ArraySlice<UInt8>) -> FileProviderChangeEntity? {
        let fields = String(decoding: line, as: UTF8.self).split(separator: " ")
        guard fields.count == 2 else {
            return nil
        }
        return FileProviderChangeEntity(
            identifier: NSFileProviderItemIdentifier(String(fields[0])),
            folderIdentifier: NSFileProviderItemIdentifier(String(fields[1]))
        )
    }
}
