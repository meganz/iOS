import Foundation

extension PhotosViewModel {
    
    // MARK: - Sort
    
    func sortOrderType(forKey key: SortingKeys) -> SortOrderType {
        let sortType = SortOrderType(megaSortOrderType: Helper.sortType(for: key.rawValue))
        return sortType != .newest && sortType != .oldest ? .newest : sortType
    }
    
    // MARK: - Filter
    
    func filter(nodes: inout [MEGANode], with type: PhotosFilterOptions) {
        guard type != .allMedia else { return }
        
        if type == .images {
            nodes = nodes.filter({ $0.name?.mnz_isImagePathExtension == true && $0.hasThumbnail() })
        } else {
            nodes = nodes.filter({ $0.name?.mnz_isVideoPathExtension == true && $0.hasThumbnail() })
        }
    }
}
