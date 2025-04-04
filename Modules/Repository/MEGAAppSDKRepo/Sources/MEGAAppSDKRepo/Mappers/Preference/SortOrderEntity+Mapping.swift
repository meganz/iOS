import MEGADomain
import MEGASdk

extension SortOrderEntity {
    public func toMEGASortOrderType() -> MEGASortOrderType {
        switch self {
        case .none:
            return .none
        case .defaultAsc:
            return .defaultAsc
        case .defaultDesc:
            return .defaultDesc
        case .sizeAsc:
            return .sizeAsc
        case .sizeDesc:
            return .sizeDesc
        case .creationAsc:
            return .creationAsc
        case .creationDesc:
            return .creationDesc
        case .modificationAsc:
            return .modificationAsc
        case .modificationDesc:
            return .modificationDesc
        case .linkCreationAsc:
            return .linkCreationAsc
        case .linkCreationDesc:
            return .linkCreationDesc
        case .labelAsc:
            return .labelAsc
        case .labelDesc:
            return .labelDesc
        case .favouriteAsc:
            return .favouriteAsc
        case .favouriteDesc:
            return .favouriteDesc
        }
    }
    
    public init?(megaSortOrderTypeCode: Int) {
        guard let sortOrderEntity = MEGASortOrderType(rawValue: megaSortOrderTypeCode)?.toSortOrderEntity() else {
            return nil
        }
        self = sortOrderEntity
    }
}

extension MEGASortOrderType {
    public func toSortOrderEntity() -> SortOrderEntity {
        switch self {
        case .none:
            return .none
        case .defaultAsc:
            return .defaultAsc
        case .defaultDesc:
            return .defaultDesc
        case .sizeAsc:
            return .sizeAsc
        case .sizeDesc:
            return .sizeDesc
        case .creationAsc:
            return .creationAsc
        case .creationDesc:
            return .creationDesc
        case .modificationAsc:
            return .modificationAsc
        case .modificationDesc:
            return .modificationDesc
        case .linkCreationAsc:
            return .linkCreationAsc
        case .linkCreationDesc:
            return .linkCreationDesc
        case .labelAsc:
            return .labelAsc
        case .labelDesc:
            return .labelDesc
        case .favouriteAsc:
            return .favouriteAsc
        case .favouriteDesc:
            return .favouriteDesc
        default:
            return .none
        }
    }
}
