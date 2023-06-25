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
