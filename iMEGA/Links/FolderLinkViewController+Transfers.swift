import Foundation

extension FolderLinkViewController: MEGATransferDelegate {
    
    public func onTransferStart(_ api: MEGASdk, transfer: MEGATransfer) {
        if let node = nodeFromDownload(transfer: transfer) {
            didDownloadTransferStart(node)
        }
    }
    
    public func onTransferUpdate(_ api: MEGASdk, transfer: MEGATransfer) {
        if let node = nodeFromDownload(transfer: transfer) {
            didDownloadTransferUpdated(node, transferredBytes: transfer.transferredBytes, totalBytes: transfer.totalBytes, speed: transfer.speed)
        }
    }
    
    public func onTransferFinish(_ api: MEGASdk, transfer: MEGATransfer, error: MEGAError) {
        if let node = nodeFromDownload(transfer: transfer) {
            didDownloadTransferFinish(node)
        }
    }
    
    private func nodeFromDownload(transfer: MEGATransfer) -> MEGANode? {
        guard isOffline(transfer: transfer),
              isFromFolderLink(node: transfer.node()) else { return nil }
        return transfer.node()
    }
    
    private func isOffline(transfer: MEGATransfer) -> Bool {
        !transfer.isStreamingTransfer && transfer.type == .download
    }
    
    private func isFromFolderLink(node: MEGANode?) -> Bool {
        guard let node = node else { return false }
        return nodesArray.contains(node)
    }
}

