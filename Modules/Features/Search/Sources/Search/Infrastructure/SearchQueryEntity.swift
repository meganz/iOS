import MEGAUIComponent

/// Represents a single search request with some properties
public struct SearchQueryEntity: Equatable, Sendable {
    public let query: String
    /// Indicates if the search interface is active or inactive when the query search is triggered.
    ///
    /// This property is crucial for rendering distinct Empty views based on the current state of the search interface, whether it is active or inactive.
    public let isSearchActive: Bool
    public let sorting: SortOrder
    public let mode: SearchModeEntity
    public let chips: [SearchChipEntity]

    public init(
        query: String,
        sorting: SortOrder,
        mode: SearchModeEntity,
        isSearchActive: Bool,
        chips: [SearchChipEntity]
    ) {
        self.query = query
        self.sorting = sorting
        self.mode = mode
        self.isSearchActive = isSearchActive
        self.chips = chips
    }

    public func clearingChips() -> SearchQueryEntity {
        .init(query: query, sorting: sorting, mode: mode, isSearchActive: isSearchActive, chips: [])
    }
}

/// Specifies the context in which the search is happening
/// currently only home
/// next stages could be:
/// .cloudDrive(rootNode: Node)
/// .incomingShares
/// .chats
/// .outgoingShares
/// .offlineFiles
public enum SearchModeEntity: Sendable {
    case home
}
