import Foundation

public enum SortOrderPreferenceKeyEntity: String {
    case cameraUploadExplorerFeed
    case homeVideos
    
    public var appearancePreferenceKeyEntity: AppearancePreferenceKeyEntity {
        switch self {
        case .cameraUploadExplorerFeed:
            return .cameraUploadExplorerFeed
        case .homeVideos:
            return .homeVideos
        }
    }
}
