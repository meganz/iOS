import MEGAAnalyticsiOS
import MEGAPresentation

extension DIContainer {
    static let timelineEvent = TimelineTabEvent()
    static let albumEvent = AlbumsTabEvent()
    static let albumImportScreenEvent = AlbumImportScreenEvent()
    static let importAlbumContentLoadedEvent = ImportAlbumContentLoadedEvent()
    static let albumImportInputDecryptionKeyDialogEvent = AlbumImportInputDecryptionKeyDialogEvent()
    static let albumImportSaveToDeviceButtonEvent = AlbumImportSaveToDeviceButtonEvent()
    static let albumImportSaveToCloudDriveButtonEvent = AlbumImportSaveToCloudDriveButtonEvent()
    static let singlePhotoSelectedEvent = PhotoItemSelectedEvent(selectionType: .single)
}
