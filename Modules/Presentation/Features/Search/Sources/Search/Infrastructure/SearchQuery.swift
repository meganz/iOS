/// Represents a type of query sent to the result provider
/// there are some special types including initial searchQuery
/// which is triggered when the results screen appears
/// the actual place being search can differ, hence it's
/// abstracted from the SearchQuery type and has to be decied by the parent
public enum SearchQuery: Equatable, Sendable {
    case initial
    case userSupplied(SearchQueryEntity)
    
    var chips: [SearchChipEntity] {
        switch self {
        case .initial:
            return []
        case .userSupplied(let query):
            return query.chips
        }
    }
    
    var query: String {
        switch self {
        case .initial:
            return ""
        case .userSupplied(let query):
            return query.query
        }
    }
    
    /// Indicates if the search interface is active or inactive when the query search is triggered.
    ///
    /// This property is crucial for rendering distinct Empty views based on the current state of the search interface, whether it is active or inactive.
    public var isSearchActive: Bool {
        switch self {
        case .initial:
            return false
        case .userSupplied(let searchQueryEntity):
            return searchQueryEntity.isSearchActive
        }
    }

    public var sorting: SortOrderEntity {
        switch self {
        case .initial:
            return .nameAscending
        case .userSupplied(let query):
            return query.sorting
        }
    }
    
    var mode: SearchModeEntity {
        .home
    }
}
