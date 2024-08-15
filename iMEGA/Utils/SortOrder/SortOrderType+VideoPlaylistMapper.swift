import MEGADomain

extension SortOrderType {
    func toVideoPlaylistSortOrderEntity() -> SortOrderEntity {
        switch self {
        case .newest:
            return .modificationDesc
        case .oldest:
            return .modificationAsc
        default:
            return .modificationDesc
        }
    }
}

extension SortOrderEntity {
    func toVideoPlaylistSortOrderEntity() -> SortOrderEntity {
        switch self {
        case .modificationDesc:
            return .modificationDesc
        case .modificationAsc:
            return .modificationAsc
        default:
            return .modificationDesc
        }
    }
}
