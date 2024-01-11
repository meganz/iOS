extension DeviceCenterActionType {
    func sortType() -> SortType {
        switch self {
        case .sortAscending: .ascending
        case .sortDescending: .descending
        case .sortLargest: .largest
        case .sortSmallest: .smallest
        case .sortNewest: .newest
        case .sortOldest: .oldest
        case .sortLabel: .label
        case .sortFavourite: .favourite
        default: .ascending
        }
    }
}

extension SortType {
    func actionType() -> DeviceCenterActionType {
        switch self {
        case .ascending: .sortAscending
        case .descending: .sortDescending
        case .largest: .sortLargest
        case .smallest: .sortSmallest
        case .newest: .sortNewest
        case .oldest: .sortOldest
        case .label: .sortLabel
        case .favourite: .sortFavourite
        }
    }
}
