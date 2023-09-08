import MEGASdk

public extension MEGASdk {
    /// Associates a `NSMutableArray` of completed transfers with every **instance** of `MEGASdk`
    private static var completedTransfers = [ObjectIdentifier: NSMutableArray]()

    @objc var completedTransfers: NSMutableArray {
        let key = ObjectIdentifier(self)

        if let completedTransfers = MEGASdk.completedTransfers[key] {
            return completedTransfers
        }

        let completedTransfers = NSMutableArray()
        MEGASdk.completedTransfers[key] = completedTransfers
        return completedTransfers
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

    @objc func removeMEGADelegateAsync(_ delegate: any MEGADelegate) {
        Task.detached {
            MEGASdk.sharedSdk.remove(delegate)
        }
    }
    
    @objc func removeMEGARequestDelegateAsync(_ delegate: any MEGARequestDelegate) {
        Task.detached {
            MEGASdk.sharedSdk.remove(delegate)
        }
    }
    
    @objc func removeMEGAGlobalDelegateAsync(_ delegate: any MEGAGlobalDelegate) {
        Task.detached {
            MEGASdk.sharedSdk.remove(delegate)
        }
    }
    
    @objc func removeMEGATransferDelegateAsync(_ delegate: any MEGATransferDelegate) {
        Task.detached {
            MEGASdk.sharedSdk.remove(delegate)
        }
    }
}
