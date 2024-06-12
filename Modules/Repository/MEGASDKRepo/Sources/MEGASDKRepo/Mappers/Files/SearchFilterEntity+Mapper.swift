import Foundation
import MEGADomain
import MEGASdk

extension SearchFilterEntity {
    
    /// Converts self into the sdk MEGASearchFilter structure
    /// - Parameter defaultParentHandle: The default root handle to use when the parentNode is nil. This should generally pass the root node.
    /// - Returns: MEGASearchFilter
    func toMEGASearchFilter(defaultParentHandle: HandleEntity) -> MEGASearchFilter {
        let term = searchText ?? ""
        let nodeType = (nodeTypeEntity ?? NodeTypeEntity.unknown).toInt32()
        let category = formatType.toInt32()
        let favouriteFilter = favouriteFilterOption.toInt32()
        
        let timeFrame: MEGASearchFilterTimeFrame? = if let modificationTimeFrame {
            MEGASearchFilterTimeFrame(
                lowerLimit: modificationTimeFrame.startDate,
                upperLimit: modificationTimeFrame.endDate
            )
        } else { nil }
        
        return if let parentNode {
            MEGASearchFilter(
                term: term,
                parentNodeHandle: parentNode.handle,
                nodeType: nodeType,
                category: category,
                sensitivity: excludeSensitive,
                favouriteFilter: favouriteFilter,
                creationTimeFrame: nil,
                modificationTimeFrame: timeFrame
            )
        } else if let folderTargetEntity {
            MEGASearchFilter(
                term: term,
                nodeType: nodeType,
                category: category,
                sensitivity: excludeSensitive,
                favouriteFilter: favouriteFilter,
                locationType: folderTargetEntity.toInt32(),
                creationTimeFrame: nil,
                modificationTimeFrame: timeFrame
            )
        } else {
            MEGASearchFilter(
                term: term,
                parentNodeHandle: defaultParentHandle,
                nodeType: nodeType,
                category: category,
                sensitivity: excludeSensitive,
                favouriteFilter: favouriteFilter,
                creationTimeFrame: nil,
                modificationTimeFrame: timeFrame
            )
        }
    }
}

extension SearchFilterEntity.FavouriteFilterOption {
    func toInt32() -> Int32 {
        switch self {
        case .disabled: 0
        case .onlyFavourites: 1
        case .excludeFavourites: 2
        }
    }
}
