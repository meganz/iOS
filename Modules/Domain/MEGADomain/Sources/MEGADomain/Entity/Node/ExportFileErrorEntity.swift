public enum ExportFileErrorEntity: Error {
    case generic
    case couldNotFindNodeByHandle
    case nodeNameUndefined
    case downloadFailed
    case nonExportableMessage
    case failedToExportText
    case failedToCreateContact
}
