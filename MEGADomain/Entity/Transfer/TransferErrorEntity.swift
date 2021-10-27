enum TransferErrorEntity: Error {
    case generic
    case upload
    case download
    case createDirectory
    case couldNotFindNodeByHandle
    case overquota
}
