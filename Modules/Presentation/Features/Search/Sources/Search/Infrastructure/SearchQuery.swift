/// Represents a type of query sent to the result provider
/// there are some special types including initial searchQuery
/// which is triggered when the results screen appears
/// the actual place being search can differ, hence it's
/// abstracted from the SearchQuery type and has to be decied by the parent
public enum SearchQuery: Equatable, Sendable {
    case initial
    case userSupplied(SearchQueryEntity)
    
    public var chips: [SearchChipEntity] {
        switch self {
        case .initial:
            return []
        case .userSupplied(let query):
            return query.chips
        }
    }
    
    public var query: String {
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

    public mutating func clearChips() {
        guard chips.isNotEmpty, case .userSupplied(var query) = self else { return }
        query.clearChips()
        self = .userSupplied(query)
    }
}

extension SearchQuery {
    public var selectedNodeType: SearchChipEntity.NodeType? {
        guard let nodeTypeChipEntity = chips.first(where: { $0.type.isNodeTypeChip }) else { return nil }
        guard case let SearchChipEntity.ChipType.nodeType(nodeType) = nodeTypeChipEntity.type else { return nil }
        return nodeType
    }
    
    public var selectedNodeFormat: SearchChipEntity.NodeFormat? {
        guard let nodeFormatChipEntity = chips.first(where: { $0.type.isNodeFormatChip }) else { return nil }
        guard case let SearchChipEntity.ChipType.nodeFormat(nodeFormat) = nodeFormatChipEntity.type else { return nil }
        return nodeFormat
    }
    
    public var selectedModificationTimeFrame: SearchChipEntity.TimeFrame? {
        guard let timeFilterChipEntity = chips.first(where: { $0.type.isTimeFilterChip }) else { return nil }
        guard case let SearchChipEntity.ChipType.timeFrame(timeFrame) = timeFilterChipEntity.type else { return nil }
        return timeFrame
    }
}
