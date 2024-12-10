import Foundation

@MainActor
extension [DeviceCenterItemViewModel] {
    func sorted(by sortType: SortType) -> [DeviceCenterItemViewModel] {
        switch sortType {
        case .ascending, .descending: sortedByName(ascending: sortType == .ascending)
        case .largest, .smallest: sortedByNodeSize(largestFirst: sortType == .largest)
        case .newest, .oldest: sortedByCreationTime(newestFirst: sortType == .newest)
        case .label: sortedByLabel()
        case .favourite: sortedByFavourite()
        }
    }
    
    private func sortedByName(ascending: Bool) -> [DeviceCenterItemViewModel] {
        sorted {
            ascending ? $0.name < $1.name : $0.name > $1.name
        }
    }

    private func sortedByNodeSize(largestFirst: Bool) -> [DeviceCenterItemViewModel] {
        sorted {
            let lhsSize = $0.nodeForItemType()?.size ?? 0
            let rhsSize = $1.nodeForItemType()?.size ?? 0
            return largestFirst ? (lhsSize > rhsSize) : (lhsSize < rhsSize)
        }
    }

    private func sortedByCreationTime(newestFirst: Bool) -> [DeviceCenterItemViewModel] {
        sorted {
            let lhsDate = $0.nodeForItemType()?.creationTime ?? Date()
            let rhsDate = $1.nodeForItemType()?.creationTime ?? Date()
            return newestFirst ? (lhsDate > rhsDate) : (lhsDate < rhsDate)
        }
    }
    
    private func sortedByLabel() -> [DeviceCenterItemViewModel] {
        sorted {
            let lhsLabel = $0.nodeForItemType()?.label ?? .unknown
            let rhsLabel = $1.nodeForItemType()?.label ?? .unknown
            return lhsLabel.stringForType() > rhsLabel.stringForType()
        }
    }

    private func sortedByFavourite() -> [DeviceCenterItemViewModel] {
        let favouriteArray = filter { $0.nodeForItemType()?.isFavourite ?? false }
            .sortedByName(ascending: true)
        let notFavouriteArray = filter { !($0.nodeForItemType()?.isFavourite ?? false) }
            .sortedByName(ascending: true)
        return favouriteArray + notFavouriteArray
    }
}
