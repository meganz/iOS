import Foundation

public enum SortOrderPreferenceKeyEntity: String {
    case cameraUploadExplorerFeed
    case homeVideos
    case homeVideoPlaylists
    case videoPlaylistContent
    case homeFavourites
    
    public var appearancePreferenceKeyEntity: AppearancePreferenceKeyEntity {
        switch self {
        case .cameraUploadExplorerFeed:
            return .cameraUploadExplorerFeed
        case .homeVideos:
            return .homeVideos
        case .homeVideoPlaylists:
            return .homeVideoPlaylists
        case .videoPlaylistContent:
            return .videoPlaylistContent
        case .homeFavourites:
            return .homeFavourites
        }
    }
}
