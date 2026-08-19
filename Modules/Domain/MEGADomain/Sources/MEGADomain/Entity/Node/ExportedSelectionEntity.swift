import Foundation

/// A whole selection made ready to be handed over, counted in files rather than in the nodes that were
/// picked.
///
/// A selection can hold folders, and a folder is one node but many files. Counting in nodes would report a
/// folder that lost seven of its files as one thing missing, so the totals here add up what each node
/// amounts to: a file as itself, a folder as what it holds.
public struct ExportedSelectionEntity: Sendable, Equatable {
    /// Everything there is to hand over. One URL per node that produced anything, so a folder appears once
    /// however many files are inside it.
    public let urls: [URL]
    /// How many files the selection was found to amount to.
    public let requestedFileCount: Int
    /// How many of those files are under `urls`.
    public let downloadedFileCount: Int

    public init(urls: [URL], requestedFileCount: Int, downloadedFileCount: Int) {
        self.urls = urls
        self.requestedFileCount = requestedFileCount
        self.downloadedFileCount = downloadedFileCount
    }
}

public extension ExportedSelectionEntity {
    static let nothing = ExportedSelectionEntity(urls: [], requestedFileCount: 0, downloadedFileCount: 0)

    /// Folds one node's outcome into the totals, so a selection can be built up as its nodes come back
    /// rather than gathered and counted afterwards.
    func adding(_ node: ExportedNodeEntity) -> ExportedSelectionEntity {
        ExportedSelectionEntity(
            urls: node.url.map { urls + [$0] } ?? urls,
            requestedFileCount: requestedFileCount + node.requestedFileCount,
            downloadedFileCount: downloadedFileCount + node.downloadedFileCount
        )
    }
}
