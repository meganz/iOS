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
    case moveFileToUploadsFolderFailed
    case cancelled
    case authorizeNodeFailed
}
