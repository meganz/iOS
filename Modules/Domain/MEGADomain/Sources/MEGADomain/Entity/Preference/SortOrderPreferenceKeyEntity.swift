import Foundation

public enum SortOrderPreferenceKeyEntity: String {
    case cameraUploadExplorerFeed
    case homeVideos
    case homeVideoPlaylists
    case videoPlaylistContent
    
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
        }
    }
}
