import MEGADomain

enum BatchDownloadEvent: Sendable {
    case fileFinished(TransferResponseEntity)
    case batchFailed
}
