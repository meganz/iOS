/// Represents a single search request with some properties
public struct SearchQueryEntity: Equatable, Sendable {
    public let query: String
    public let sorting: SortOrderEntity
    public let mode: SearchModeEntity
    public let chips: [SearchChipEntity]

    public init(query: String, sorting: SortOrderEntity, mode: SearchModeEntity, chips: [SearchChipEntity]) {
        self.query = query
        self.sorting = sorting
        self.mode = mode
        self.chips = chips
    }
}

/// default value, iteration one of search project does not allow specifying sort order but that can come in next stages
public enum SortOrderEntity: Sendable {
    case automatic
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
