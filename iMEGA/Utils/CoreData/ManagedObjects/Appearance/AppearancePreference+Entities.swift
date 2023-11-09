import Foundation
import MEGADomain

extension AppearancePreference {
    
    var sortOrderEntity: SortOrderEntity? {
        guard let megaSortTypeRawValue = sortType?.intValue else {
            return nil
        }
        
        return MEGASortOrderType(rawValue: megaSortTypeRawValue)?.toSortOrderEntity()
    }
    
    var viewModeEntity: ViewModePreferenceEntity? {
        guard let viewModeRawValue = viewMode?.intValue else {
            return nil
        }
        
        return ViewModePreference(rawValue: viewModeRawValue)?.toViewModePreferenceEntity()
    }
}
