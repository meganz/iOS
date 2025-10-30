import MEGADomain
import Search

extension ViewModePreferenceEntity {
    func toSearchResultsViewMode() -> SearchResultsViewMode {
        switch self {
        case .perFolder, .list: .list
        case .thumbnail: .grid
        case .mediaDiscovery: .mediaDiscovery
        }
    }
}

extension SearchResultsViewMode {
    func toViewModePreferenceEntity() -> ViewModePreferenceEntity {
        switch self {
        case .list: .list
        case .grid: .thumbnail
        case .mediaDiscovery: .mediaDiscovery
        }
    }
}
