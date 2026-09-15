/// Using raw value here is intented because the appData is app defined logic
public enum TransferMetaDataEntity: String, Sendable {
    case exportFile = ">exportFile" // When download and "export file" to another application
    case saveInPhotos = ">SaveInPhotosApp" // When download and save to Photos.app
    case makeAvailableOffline = ">makeAvailableOffline" // When user triggers "Make available offline" on a node
}
