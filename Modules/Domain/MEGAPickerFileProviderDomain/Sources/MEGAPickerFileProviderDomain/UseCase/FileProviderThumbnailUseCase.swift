import FileProvider
import MEGADomain

/// Loads the thumbnails Files shows for the items of the File Provider extension.
public protocol FileProviderThumbnailUseCaseProtocol: Sendable {
    /// Loads the thumbnails of `identifiers`, a few at a time, and reports each one from the calling task as it is
    /// loaded: its image data, `nil` when the item has none, or the error that loading it failed with. Once the calling
    /// task is cancelled, no more are loaded or reported.
    func loadThumbnails(
        for identifiers: [NSFileProviderItemIdentifier],
        onLoaded: (NSFileProviderItemIdentifier, Result<Data?, any Error>) -> Void
    ) async
}

public struct FileProviderThumbnailUseCase: FileProviderThumbnailUseCaseProtocol {
    private typealias LoadedThumbnail = (identifier: NSFileProviderItemIdentifier, result: Result<Data?, any Error>)

    private static let maxConcurrentLoads = 3

    private let itemUseCase: any FileProviderItemUseCaseProtocol
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol
    private let inFlightLoads: InFlightThumbnailLoads

    /// - Parameter inFlightLoads: Shared by the use cases built for one extension instance, so that calls overlapping in
    ///   time load each thumbnail once.
    public init(
        itemUseCase: any FileProviderItemUseCaseProtocol,
        thumbnailUseCase: any ThumbnailUseCaseProtocol,
        inFlightLoads: InFlightThumbnailLoads
    ) {
        self.itemUseCase = itemUseCase
        self.thumbnailUseCase = thumbnailUseCase
        self.inFlightLoads = inFlightLoads
    }

    public func loadThumbnails(
        for identifiers: [NSFileProviderItemIdentifier],
        onLoaded: (NSFileProviderItemIdentifier, Result<Data?, any Error>) -> Void
    ) async {
        await withTaskGroup(of: LoadedThumbnail.self) { group in
            var remaining = identifiers.makeIterator()
            for _ in 0..<Self.maxConcurrentLoads {
                guard !Task.isCancelled, let identifier = remaining.next() else { break }
                group.addTask { await loadThumbnail(for: identifier) }
            }
            while let loaded = await group.next() {
                guard !Task.isCancelled else { return }
                onLoaded(loaded.identifier, loaded.result)
                if let identifier = remaining.next() {
                    group.addTask { await loadThumbnail(for: identifier) }
                }
            }
        }
    }

    private func loadThumbnail(for identifier: NSFileProviderItemIdentifier) async -> LoadedThumbnail {
        do {
            let data = try await inFlightLoads.data(for: identifier) {
                try await thumbnailData(for: identifier)
            }
            return (identifier, .success(data))
        } catch {
            return (identifier, .failure(error))
        }
    }

    /// `nil` when the item has no thumbnail, which Files keeps until the item's contents change; an error for anything
    /// worth trying again, such as a failed request.
    private func thumbnailData(for identifier: NSFileProviderItemIdentifier) async throws -> Data? {
        let node: NodeEntity
        do {
            node = try itemUseCase.item(for: identifier).node
        } catch let error as NSFileProviderError where error.code == .noSuchItem {
            return nil
        }
        guard node.isFile, node.hasThumbnail else { return nil }
        do {
            let thumbnail = try await thumbnailUseCase.loadThumbnail(for: node, type: .thumbnail)
            return try Data(contentsOf: thumbnail.url, options: .alwaysMapped)
        } catch is ThumbnailErrorEntity {
            return nil
        }
    }
}

/// The thumbnails being loaded, shared by the calls that ask for one at the same time: the SDK deletes and rewrites the
/// cached file for every request, so a caller reading it while another request rewrites it finds no file.
public actor InFlightThumbnailLoads {
    private var loads: [NSFileProviderItemIdentifier: Task<Data?, any Error>] = [:]

    public init() {}

    /// The result of the load of `identifier` already running, or of `load` when none is.
    func data(
        for identifier: NSFileProviderItemIdentifier,
        load: @escaping @Sendable () async throws -> Data?
    ) async throws -> Data? {
        if let running = loads[identifier] {
            return try await running.value
        }
        let task = Task { try await load() }
        loads[identifier] = task
        defer { loads[identifier] = nil }
        return try await task.value
    }
}
