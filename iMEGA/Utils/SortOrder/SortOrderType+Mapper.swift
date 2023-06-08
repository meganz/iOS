import MEGADomain

extension SortOrderType {
    func toSortOrderEntity() -> SortOrderEntity {
        switch self {
        case .nameAscending:
            return .defaultAsc
        case .nameDescending:
            return .defaultDesc
        case .largest:
            return .sizeDesc
        case .smallest:
            return .sizeAsc
        case .newest:
            return .modificationDesc
        case .oldest:
            return .modificationAsc
        case .label:
            return .labelAsc
        case .favourite:
            return .favouriteAsc
        case .none:
            return .none
        }
    }
}

extension SortOrderEntity {
    func toSortOrderType() -> SortOrderType {
        switch self {
        case .defaultAsc:
            return .nameAscending
        case .defaultDesc:
            return .nameDescending
        case .sizeDesc:
            return .largest
        case .sizeAsc:
            return .smallest
        case .modificationDesc:
            return .newest
        case .modificationAsc:
            return .oldest
        case .labelAsc:
            return .label
        case .favouriteAsc:
            return .favourite
        default:
            return .none
        }
    }
}
