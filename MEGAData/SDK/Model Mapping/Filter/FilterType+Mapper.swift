import MEGADomain

extension FilterType {
    func toFilterEntity() -> FilterEntity {
        switch self {
        case .allMedia:
            return .allMedia
        case .images:
            return .images
        case .videos:
            return .videos
        case .none:
            return .none
        }
    }
}

extension FilterEntity {
    func toFilterType() -> FilterType {
        switch self {
        case .allMedia:
            return .allMedia
        case .images:
            return .images
        case .videos:
            return .videos
        default:
            return .none
        }
    }
}
