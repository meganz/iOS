import FileProvider

/// What one change enumeration of the working set tells the system.
public struct FileProviderChangeSetEntity: Sendable, Equatable {
    /// Each parent comes before its children, so a renamed or moved folder never shows up twice on disk.
    public let updatedItems: [FileProviderItemEntity]
    public let deletedIdentifiers: [NSFileProviderItemIdentifier]
    public let anchor: NSFileProviderSyncAnchor
    public let moreComing: Bool

    public init(
        updatedItems: [FileProviderItemEntity],
        deletedIdentifiers: [NSFileProviderItemIdentifier],
        anchor: NSFileProviderSyncAnchor,
        moreComing: Bool
    ) {
        self.updatedItems = updatedItems
        self.deletedIdentifiers = deletedIdentifiers
        self.anchor = anchor
        self.moreComing = moreComing
    }
}

/// One page of the working set's items.
public struct FileProviderWorkingSetPageEntity: Sendable, Equatable {
    public let items: [FileProviderItemEntity]
    /// `nil` on the last page.
    public let nextPage: NSFileProviderPage?

    public init(items: [FileProviderItemEntity], nextPage: NSFileProviderPage?) {
        self.items = items
        self.nextPage = nextPage
    }
}
