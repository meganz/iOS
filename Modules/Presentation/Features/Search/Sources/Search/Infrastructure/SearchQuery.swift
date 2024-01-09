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
    
    var sorting: SortOrderEntity {
        .automatic
    }
    
    var mode: SearchModeEntity {
        .home
    }
}
