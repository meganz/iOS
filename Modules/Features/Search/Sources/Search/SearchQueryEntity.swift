/// Represents a single search request
public struct SearchQueryEntity {
    public let query: String
    public let sorting: SortOrderEntity
    public let mode: SearchModeEntity
    public let chips: [SearchChipEntity]
}

/// default value, iteration one of search project does not allow specifying sort order but that can come in next stages
public enum SortOrderEntity {
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
public enum SearchModeEntity {
    case home
}
