public enum TransferErrorEntity: Error, CaseIterable {
    case generic
    case upload
    case download
    case nodeNameUndefined
    case createDirectory
    case couldNotFindNodeByHandle
    case couldNotFindNodeByLink
    case overquota
    case noInternetConnection
    case inboxFolderNameNotAllowed
    case alreadyDownloaded
    case copiedFromTempFolder
    case moveFileToUploadsFolderFailed
    case cancelled
    case authorizeNodeFailed
}
