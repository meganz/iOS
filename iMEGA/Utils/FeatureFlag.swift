import Foundation

final class FeatureFlag: NSObject {
    // Add your feature flag here, for example:
    // @objc static let isNewPhotosLibraryEnabled = true
    @objc static let shouldRemoveHomeImage = false
    @objc static let shouldEnableSlideShow = false
    @objc static let shouldEnableContextMenuOnCameraUploadExplorer = false
    @objc static let shouldEnableFilterMenuOnCameraUploadExplorer = false
}
