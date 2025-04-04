import MEGASdk
import MEGASwift

private let sdkQueue = DispatchQueue(label: "nz.mega.MEGASDKRepo.MEGASdkAdditions")
private let sdkCompletedTransfersProcessingQueue = DispatchQueue(label: "nz.mega.MEGASDKRepo.completedTransfersProcessingQueue")

public extension MEGASdk {
    /// Associates a `NSMutableArray` of completed transfers with every **instance** of `MEGASdk`
    private static let completedTransfers: Atomic<[ObjectIdentifier: NSMutableArray]> = .init(wrappedValue: [:])
    
    @objc var completedTransfers: NSMutableArray {
        sdkCompletedTransfersProcessingQueue.sync {
            privateCompletedTransfers
        }
    }
    
    @objc func addCompletedTransfer(_ transfer: MEGATransfer) {
        sdkCompletedTransfersProcessingQueue.async {
            let transfers = self.privateCompletedTransfers
            transfers.add(transfer)
        }
    }
    
    @objc static func currentUserHandle() -> NSNumber? {
        CurrentUserSource.shared.currentUserHandle.map {
            NSNumber(value: $0)
        }
    }
    
    @objc static var isGuest: Bool {
        CurrentUserSource.shared.isGuest
    }
    
    @objc static var currentUserEmail: String? {
        CurrentUserSource.shared.currentUserEmail
    }
    
    @objc static var isLoggedIn: Bool {
        CurrentUserSource.shared.isLoggedIn
    }
    
    @objc func removeMEGADelegateAsync(_ delegate: any MEGADelegate & Sendable) {
        sdkQueue.async { [weak self] in
            self?.remove(delegate)
        }
    }
    
    @objc func removeMEGARequestDelegateAsync(_ delegate: any MEGARequestDelegate & Sendable) {
        sdkQueue.async { [weak self] in
            self?.remove(delegate)
        }
    }
    
    @objc func addMEGAGlobalDelegateAsync(_ delegate: any MEGAGlobalDelegate & Sendable, queueType: ListenerQueueType) {
        sdkQueue.async { [weak self] in
            self?.add(delegate, queueType: queueType)
        }
    }
    
    @objc func addMEGARequestDelegateAsync(_ delegate: any MEGARequestDelegate & Sendable, queueType: ListenerQueueType) {
        sdkQueue.async { [weak self] in
            self?.add(delegate, queueType: queueType)
        }
    }
    
    @objc func removeMEGAGlobalDelegateAsync(_ delegate: any MEGAGlobalDelegate & Sendable) {
        sdkQueue.async { [weak self] in
            self?.remove(delegate)
        }
    }
    
    @objc func removeMEGATransferDelegateAsync(_ delegate: any MEGATransferDelegate & Sendable) {
        sdkQueue.async { [weak self] in
            self?.remove(delegate)
        }
    }
    
    private var privateCompletedTransfers: NSMutableArray {
        let key = ObjectIdentifier(self)
        if let completedTransfers = MEGASdk.completedTransfers.wrappedValue[key] {
            return completedTransfers
        }
        
        let completedTransfers = NSMutableArray()
        MEGASdk.completedTransfers.mutate { $0[key] = completedTransfers }
        return completedTransfers
    }
}

public extension MEGASdk {
    @objc func node(for handle: UInt64) async -> MEGANode? {
        await withCheckedContinuation { continuation in
            sdkQueue.async {
                let node = self.node(forHandle: handle)
                continuation.resume(returning: node)
            }
        }
    }
}
