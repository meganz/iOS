import Foundation

extension PhotosViewModel {
    
    // MARK: - Sort
    
    func sortOrderType(forKey key: SortingKeys) -> SortOrderType {
        let sortType = SortOrderType(megaSortOrderType: Helper.sortType(for: key.rawValue))
        return sortType != .newest && sortType != .oldest ? .newest : sortType
    }
    
    func reorderPhotos(_ sortType: SortOrderType?, mediaNodes: [MEGANode]) -> [MEGANode] {
        guard let sortType = sortType,
              sortType == .newest || sortType == .oldest else { return mediaNodes }
        
        return mediaNodes.sorted { node1, node2 in
            guard let date1 = node1.modificationTime,
                  let date2 = node2.modificationTime else { return node1.name ?? "" < node2.name ?? "" }
            
            return sortType == .newest ? date1 > date2 : date1 < date2
        }
    }
    
    // MARK: - Filter
    
    func filter(nodes: inout [MEGANode], with type: PhotosFilterOptions) {
        guard type != .allMedia else { return }
        
        if type == .images {
            nodes = nodes.filter({ $0.name?.mnz_isImagePathExtension == true })
        } else {
            nodes = nodes.filter({ $0.name?.mnz_isVideoPathExtension == true })
        }
    }
}
