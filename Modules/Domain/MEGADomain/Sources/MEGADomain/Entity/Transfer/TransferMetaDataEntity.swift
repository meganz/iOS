public enum TransferMetaDataEntity: Sendable {
    case exportFile // When download and "export file" to another application
    case saveInPhotos // When download and save to Photos.app
    case makeAvailableOffline // When user triggers "Make available offline" on a node
}
