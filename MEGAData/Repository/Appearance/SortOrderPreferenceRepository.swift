import Foundation
import MEGAAppSDKRepo
import MEGADomain

struct SortOrderPreferenceRepository: SortOrderPreferenceRepositoryProtocol {

    static var newRepo: SortOrderPreferenceRepository {
        SortOrderPreferenceRepository(store: .shareInstance())
    }
 
    private let store: MEGAStore
    
    init(store: MEGAStore) {
        self.store = store
    }
    
    func sortOrderPreferenceBasis(for code: Int) -> SortingPreferenceBasisEntity? {
        SortingPreferenceBasisEntity(sortingPreferenceBasisEntityCode: code)
    }
    
    func sortOrder(for megaSortOrderTypeCode: Int) -> SortOrderEntity? {
        SortOrderEntity(megaSortOrderTypeCode: megaSortOrderTypeCode)
    }
    
    func megaSortOrderTypeCode(for sortOrder: SortOrderEntity) -> Int {
        sortOrder.toMEGASortOrderType().rawValue
    }
    
    func sortOrder(for key: SortOrderPreferenceKeyEntity) -> SortOrderEntity? {
        preference(for: key.appearancePreferenceKeyEntity)?.sortOrder
    }
    
    func sortOrder(for nodeHandle: HandleEntity) -> SortOrderEntity? {
        preference(for: nodeHandle)?.sortOrder
    }
        
    func save(sortOrder: SortOrderEntity, for key: SortOrderPreferenceKeyEntity) {
        store.insertOrUpdateOfflineSortType(
            path: path(for: key.appearancePreferenceKeyEntity.rawValue),
            sortType: sortOrder.toMEGASortOrderType().rawValue)
    }
    
    func save(sortOrder: SortOrderEntity, for nodeHandle: HandleEntity) {
        store.insertOrUpdateCloudSortType(handle: nodeHandle, sortType: sortOrder.toMEGASortOrderType().rawValue)
    }
}

private extension SortOrderPreferenceRepository {
    
    func preference(for key: AppearancePreferenceKeyEntity) -> AppearancePreferenceEntity? {
        guard let offlineAppearancePreference = store.fetchOfflineAppearancePreference(path: path(for: key.rawValue)) else {
            return nil
        }
                
        return AppearancePreferenceEntity(
            sortOrder: offlineAppearancePreference.sortOrderEntity,
            viewModePreference: offlineAppearancePreference.viewModeEntity)
    }
    
    func preference(for nodeHandle: HandleEntity) -> AppearancePreferenceEntity? {
        guard let cloudAppearancePreference = store.fetchCloudAppearancePreference(handle: nodeHandle) else {
            return nil
        }
        
        return AppearancePreferenceEntity(
            sortOrder: cloudAppearancePreference.sortOrderEntity,
            viewModePreference: cloudAppearancePreference.viewModeEntity)
    }
    
    func path(for key: String) -> String {
        let path = Helper.pathRelative(toOfflineDirectory: key)
        guard path.isNotEmpty else {
            return "Documents"
        }
        return path
    }
}
