import MEGAAnalyticsiOS
import MEGAAppPresentation

extension DIContainer {
    static let timelineEvent = TimelineTabEvent()
    static let albumEvent = AlbumsTabEvent()
    static let albumImportScreenEvent = AlbumImportScreenEvent()
    static let importAlbumContentLoadedEvent = ImportAlbumContentLoadedEvent()
    static let albumImportInputDecryptionKeyDialogEvent = AlbumImportInputDecryptionKeyDialogEvent()
    static let albumImportSaveToDeviceButtonEvent = AlbumImportSaveToDeviceButtonEvent()
    static let albumImportSaveToCloudDriveButtonEvent = AlbumImportSaveToCloudDriveButtonEvent()
    static let singlePhotoSelectedType = PhotoItemSelected.SelectionType.single
    static let singlePhotoSelectedEvent = PhotoItemSelectedEvent(selectionType: singlePhotoSelectedType)
    static let photoScreenEvent = PhotoScreenEvent()
    static let albumListShareLinkMenuItemEvent = AlbumListShareLinkMenuItemEvent()
    static let photoPreviewScreenEvent = PhotoPreviewScreenEvent()
    static let photoPreviewSaveToDeviceMenuToolbarEvent = PhotoPreviewSaveToDeviceMenuToolbarEvent()
    static let createAlbumDialogButtonPressedEvent = CreateAlbumDialogButtonPressedEvent()
    static let addItemsToNewAlbumButtonEvent = AddItemsToNewAlbumButtonEvent()
    static let createNewAlbumDialogEvent = CreateNewAlbumDialogEvent()
    static let cameraUploadsEnabled = CameraUploadsEnabledEvent()
    static let cameraUploadsDisabled = CameraUploadsDisabledEvent()
}
