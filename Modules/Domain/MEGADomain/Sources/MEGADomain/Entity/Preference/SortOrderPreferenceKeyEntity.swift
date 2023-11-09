import Foundation

public enum SortOrderPreferenceKeyEntity: String {
    case cameraUploadExplorerFeed
    
    public var appearancePreferenceKeyEntity: AppearancePreferenceKeyEntity {
        switch self {
        case .cameraUploadExplorerFeed:
            return .cameraUploadExplorerFeed
        }
    }
}
