import MEGADomain
import Search

extension SortOrderType {
    func toSearchSortOrderEntity() -> Search.SortOrderEntity {
        switch self {
        case .none, .nameAscending:
                .nameAscending
        case .nameDescending:
                .nameDescending
        case .largest:
                .largest
        case .smallest:
                .smallest
        case .newest:
                .newest
        case .oldest:
                .oldest
        case .label:
                .label
        case .favourite:
                .favourite
        }
    }
}

extension Search.SortOrderEntity {
    func toMEGASortOrderType() -> MEGASortOrderType {
        switch self {
        case .nameAscending:
                .defaultAsc
        case .nameDescending:
                .defaultDesc
        case .largest:
                .sizeDesc
        case .smallest:
                .sizeAsc
        case .newest:
                .modificationDesc
        case .oldest:
                .modificationAsc
        case .label:
                .labelAsc
        case .favourite:
                .favouriteAsc
        }
    }

    func toDomainSortOrderEntity() -> MEGADomain.SortOrderEntity {
        switch self {
        case .nameAscending:
                .defaultAsc
        case .nameDescending:
                .defaultDesc
        case .largest:
                .sizeDesc
        case .smallest:
                .sizeAsc
        case .newest:
                .modificationDesc
        case .oldest:
                .modificationAsc
        case .label:
                .labelAsc
        case .favourite:
                .favouriteAsc
        }
    }
}

extension MEGADomain.SortOrderEntity {
    func toSearchSortOrderEntity() -> Search.SortOrderEntity {
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
            assertionFailure("Invalid case found \(self)")
            return .nameAscending
        }
    }
}
