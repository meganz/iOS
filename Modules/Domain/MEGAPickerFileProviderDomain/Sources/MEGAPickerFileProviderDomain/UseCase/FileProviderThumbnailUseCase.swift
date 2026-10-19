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

    public init(itemUseCase: any FileProviderItemUseCaseProtocol, thumbnailUseCase: any ThumbnailUseCaseProtocol) {
        self.itemUseCase = itemUseCase
        self.thumbnailUseCase = thumbnailUseCase
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
            let data = try await thumbnailData(for: identifier)
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
