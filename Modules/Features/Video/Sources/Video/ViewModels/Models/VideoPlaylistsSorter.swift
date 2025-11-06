import Foundation
import MEGADomain

enum VideoPlaylistsSorter {
    
    static func sort(_ videoPlaylists: [VideoPlaylistEntity], by sortOrder: SortOrderEntity) -> [VideoPlaylistEntity] {
        switch sortOrder {
        case .modificationAsc:
            videoPlaylists.sorted { $0.creationTime < $1.creationTime }
        case .modificationDesc:
            videoPlaylists.sorted { $0.creationTime > $1.creationTime }
        default:
            videoPlaylists
        }
    }
}
