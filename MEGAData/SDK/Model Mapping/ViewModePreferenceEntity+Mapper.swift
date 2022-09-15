import MEGADomain

extension ViewModePreferenceEntity {
    func toViewModePreference() -> ViewModePreference {
        switch self {
        case .perFolder:
            return .perFolder
        case .list:
            return .list
        case .thumbnail:
            return .thumbnail
        }
    }
}

extension ViewModePreference {
    func toViewModePreferenceEntity() -> ViewModePreferenceEntity {
        switch self {
        case .perFolder:
            return .perFolder
        case .list:
            return .list
        case .thumbnail:
            return .thumbnail
        }
        
    }
}
