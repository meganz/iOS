import Foundation

extension SortOrderEntity {
    func toSortOrderType() -> MEGASortOrderType {
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
        case .alphabeticalAsc:
            return .alphabeticalAsc
        case .alphabeticalDesc:
            return .alphabeticalDesc
        case .photoAsc:
            return .photoAsc
        case .photoDesc:
            return .photoDesc
        case .videoAsc:
            return .videoAsc
        case .videoDesc:
            return .videoDesc
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
        @unknown default:
            return .none
        }
    }
}

extension MEGASortOrderType {
    func toSortOrderEntity() -> SortOrderEntity {
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
        case .alphabeticalAsc:
            return .alphabeticalAsc
        case .alphabeticalDesc:
            return .alphabeticalDesc
        case .photoAsc:
            return .photoAsc
        case .photoDesc:
            return .photoDesc
        case .videoAsc:
            return .videoAsc
        case .videoDesc:
            return .videoDesc
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
        @unknown default:
            return .none
        }
    }
}
