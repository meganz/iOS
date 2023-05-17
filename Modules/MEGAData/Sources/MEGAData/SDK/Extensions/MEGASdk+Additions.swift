import MEGASdk

public extension MEGASdk {
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
    
    @objc func removeMEGADelegateAsync(_ delegate: MEGADelegate) {
        Task.detached {
            MEGASdk.sharedSdk.remove(delegate)
        }
    }
    
    @objc func removeMEGARequestDelegateAsync(_ delegate: MEGARequestDelegate) {
        Task.detached {
            MEGASdk.sharedSdk.remove(delegate)
        }
    }
    
    @objc func removeMEGAGlobalDelegateAsync(_ delegate: MEGAGlobalDelegate) {
        Task.detached {
            MEGASdk.sharedSdk.remove(delegate)
        }
    }
}
