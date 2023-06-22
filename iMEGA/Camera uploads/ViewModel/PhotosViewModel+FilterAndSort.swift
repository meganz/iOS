import Foundation
import MEGADomain

extension PhotosViewModel {
    // MARK: - Sort
    
    func sortOrderType(forKey key: SortingKeys) -> SortOrderType {
        let sortType = SortOrderType(megaSortOrderType: Helper.sortType(for: key.rawValue))
        return sortType != .newest && sortType != .oldest ? .newest : sortType
    }
    
    // MARK: - Filter
    
    func filter(nodes: inout [NodeEntity], with type: PhotosFilterOptions) {
        if type == .allMedia {
            nodes = nodes.filter { $0.hasThumbnail }
        } else if type == .images {
            nodes = nodes.filter { String.fileExtensionGroup(verify: $0.name, \.isImage) && $0.hasThumbnail }
        } else if type == .videos {
            nodes = nodes.filter { String.fileExtensionGroup(verify: $0.name, \.isVideo) && $0.hasThumbnail }
        }
    }
    
    @objc func hasNoPhotos() -> Bool {
        mediaNodes.isEmpty
    }
}
