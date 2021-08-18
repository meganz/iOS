import Foundation

extension FolderLinkViewController: MEGATransferDelegate {
    
    public func onTransferStart(_ api: MEGASdk, transfer: MEGATransfer) {
        guard !transfer.isStreamingTransfer,
              transfer.type == .download,
              let node = transfer.node(),
              nodesArray.contains(node) else { return }
        
        didDownloadTransferStart(node)
    }
    
    public func onTransferUpdate(_ api: MEGASdk, transfer: MEGATransfer) {
        guard !transfer.isStreamingTransfer,
              transfer.type == .download,
              let node = transfer.node(),
              nodesArray.contains(node) else { return }
        didDownloadTransferUpdated(node, transferredBytes: transfer.transferredBytes, totalBytes: transfer.totalBytes, speed: transfer.speed)
    }
    
    public func onTransferFinish(_ api: MEGASdk, transfer: MEGATransfer, error: MEGAError) {
        guard transfer.type == .download,
              let node = transfer.node(),
              nodesArray.contains(node) else { return }
        
        didDownloadTransferFinish(node)
    }
}

