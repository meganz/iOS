/// Represents a single search request with some properties
public struct SearchQueryEntity: Equatable, Sendable {
    public let query: String
    /// Indicates if the search interface is active or inactive when the query search is triggered.
    ///
    /// This property is crucial for rendering distinct Empty views based on the current state of the search interface, whether it is active or inactive.
    public let isSearchActive: Bool
    public let sorting: SortOrderEntity
    public let mode: SearchModeEntity
    public let chips: [SearchChipEntity]

    public init(
        query: String,
        sorting: SortOrderEntity,
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

/// default value, iteration one of search project does not allow specifying sort order but that can come in next stages
public struct SortOrderEntity: Hashable, Sendable {
    public enum Key: Hashable, Sendable {
        case name
        case favourite
        case label
        case dateAdded
        case lastModified
        case size
    }

    public enum Direction: Hashable, Sendable {
        case ascending
        case descending

        func toggled() -> Self {
            switch self {
            case .ascending: .descending
            case .descending: .ascending
            }
        }
    }

    public var key: Key
    public var direction: Direction

    public init(key: Key, direction: Direction = .ascending) {
        self.key = key
        self.direction = direction
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
