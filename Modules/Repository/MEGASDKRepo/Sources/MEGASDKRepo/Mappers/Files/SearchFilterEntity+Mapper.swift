import Foundation
import MEGADomain
import MEGASdk

extension SearchFilterEntity {
    
    /// Converts self into the sdk MEGASearchFilter structure
    /// - Parameter defaultParentHandle: The default root handle to use when the parentNode is nil. This should generally pass the root node.
    /// - Returns: MEGASearchFilter
    func toMEGASearchFilter(defaultParentHandle: HandleEntity) -> MEGASearchFilter {
        MEGASearchFilter(
            term: searchText ?? "",
            parentNodeHandle: parentNode?.handle ?? defaultParentHandle,
            nodeType: Int32(MEGANodeType.unknown.rawValue),
            category: formatType.toInt32(),
            sensitivity: excludeSensitive,
            creationTimeFrame: nil,
            modificationTimeFrame: nil)
    }
}
