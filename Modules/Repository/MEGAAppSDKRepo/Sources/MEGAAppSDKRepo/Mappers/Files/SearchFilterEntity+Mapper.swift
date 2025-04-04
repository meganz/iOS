import Foundation
import MEGADomain
import MEGASdk

extension SearchFilterEntity {
    
    /// Converts self into the sdk MEGASearchFilter structure
    /// - Parameter defaultParentHandle: The default root handle to use when the parentNode is nil. This should generally pass the root node.
    /// - Returns: MEGASearchFilter
    func toMEGASearchFilter() -> MEGASearchFilter {
        let term = searchText ?? ""
        let nodeType = nodeTypeEntity.toMEGANodeType()
        let category = formatType.toMEGANodeFormatType()
        let favouriteFilter = favouriteFilterOption.toMEGASearchFilterFavouriteOption()
        let sensitiveFilter = sensitiveFilterOption.toMEGASearchFilterSensitiveOption()
        let timeFrame: MEGASearchFilterTimeFrame? = if let modificationTimeFrame {
            MEGASearchFilterTimeFrame(
                lowerLimit: modificationTimeFrame.startDate,
                upperLimit: modificationTimeFrame.endDate
            )
        } else { nil }
        
        return switch searchTargetLocation {
        case .parentNode(let parentNode):
            MEGASearchFilter(
                term: term,
                description: searchDescription,
                tag: searchTag,
                parentNodeHandle: parentNode.handle,
                nodeType: nodeType,
                category: category,
                sensitiveFilter: sensitiveFilter,
                favouriteFilter: favouriteFilter,
                creationTimeFrame: nil,
                modificationTimeFrame: timeFrame,
                useAndForTextQuery: useAndForTextQuery
            )
        case .folderTarget(let folderTargetEntity):
            MEGASearchFilter(
                term: term,
                description: searchDescription,
                tag: searchTag,
                nodeType: nodeType,
                category: category,
                sensitiveFilter: sensitiveFilter,
                favouriteFilter: favouriteFilter,
                locationType: folderTargetEntity.toInt32(),
                creationTimeFrame: nil,
                modificationTimeFrame: timeFrame,
                useAndForTextQuery: useAndForTextQuery
            )
        }
    }
}

extension SearchFilterEntity.FavouriteFilterOption {
    
    func toMEGASearchFilterFavouriteOption() -> MEGASearchFilterFavouriteOption {
        switch self {
        case .disabled: .disabled
        case .onlyFavourites: .favouritesOnly
        case .excludeFavourites: .nonFavouritesOnly
        }
    }
}

extension SearchFilterEntity.SensitiveFilterOption {
    public func toMEGASearchFilterSensitiveOption() -> MEGASearchFilterSensitiveOption {
        switch self {
        case .disabled: .disabled
        case .nonSensitiveOnly: .nonSensitiveOnly
        case .sensitiveOnly: .sensitiveOnly
        }
    }
}
