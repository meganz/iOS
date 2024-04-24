import MEGASdk

public protocol OfflineStoreBridgeProtocol: Sendable {
    func isDownloaded(node: MEGANode) -> Bool
}
