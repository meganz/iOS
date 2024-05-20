import Foundation
import MEGADomain
import MEGASdk

extension SearchFilterEntity {
    
    /// Converts self into the sdk MEGASearchFilter structure
    /// - Parameter defaultParentHandle: The default root handle to use when the parentNode is nil. This should generally pass the root node.
    /// - Returns: MEGASearchFilter
    func toMEGASearchFilter(defaultParentHandle: HandleEntity) -> MEGASearchFilter {
        var timeFrame: MEGASearchFilterTimeFrame?
        if let modificationTimeFrame {
            timeFrame = MEGASearchFilterTimeFrame(
                lowerLimit: modificationTimeFrame.startDate,
                upperLimit: modificationTimeFrame.endDate
            )
        }
        
        return MEGASearchFilter(
            term: searchText ?? "",
            parentNodeHandle: parentNode?.handle ?? defaultParentHandle,
            nodeType: (nodeTypeEntity ?? NodeTypeEntity.unknown).toInt32(),
            category: formatType.toInt32(),
            sensitivity: excludeSensitive,
            creationTimeFrame: nil,
            modificationTimeFrame: timeFrame
        )
    }
}
