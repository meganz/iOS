import Foundation

/// A node made ready to be handed over, and how much of it made it there.
///
/// Unlike a file, a folder can be worth handing over while still being short of what was asked for, so the
/// URL alone does not say whether the export is complete.
public struct ExportedNodeEntity: Sendable, Equatable {
    /// Where the node can be handed over from, or `nil` when nothing of it arrived and there is
    /// nothing to hand over.
    public let url: URL?
    /// How many files this node amounts to: one for a file, and however many it holds for a folder.
    public let fileCount: Int
    /// How many of those files are under `url`.
    public let downloadedFileCount: Int

    /// What this node counts as when reporting a shortfall.
    ///
    /// Its own files wherever it has a count of them, and otherwise itself: one thing asked for, and by
    /// `url` either delivered or not. An empty folder asks for nothing, and so is missing nothing.
    ///
    /// Never less than what arrived, whatever the counts say. A selection adds both fields up, so a node
    /// claiming to have delivered more than it asked for would cancel out a sibling's real shortfall and
    /// take the warning with it. Where the two disagree, what is on disk is the part that is certain.
    public var requestedFileCount: Int {
        let requested = if fileCount == 0 { url == nil ? 1 : 0 } else { fileCount }
        return max(requested, downloadedFileCount)
    }

    public init(url: URL?, fileCount: Int, downloadedFileCount: Int) {
        self.url = url
        self.fileCount = fileCount
        self.downloadedFileCount = downloadedFileCount
    }
}
