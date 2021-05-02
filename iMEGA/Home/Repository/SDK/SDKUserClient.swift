import Foundation

struct SDKUserClient {
    
    /// Will return current login user in `MEGASDK` and return a `UserSDKEntity` that encapsulates the `MEGAUser` instance.
    var currentUser: () -> UserSDKEntity?
    
    var hasUserLoggedIn: () -> Bool
    
    /// Will return the owner user of specified shared node in `MEGASDK`.
    /// - Parameter: Shared node's node handle.
    var userForSharedNode: (
        _ nodeHandle: MEGAHandle
    ) -> UserSDKEntity?
}

extension SDKUserClient {

    static var live: Self {
        let api = MEGASdkManager.sharedMEGASdk()

        return Self(
            currentUser: {
                guard let user = api.myUser else { return nil }
                let base64Handle = MEGASdk.base64Handle(forUserHandle: user.handle)
                return UserSDKEntity(with: user, base64Handle: base64Handle)
            },
            hasUserLoggedIn: {
                api.isLoggedIn() > 0
            },
            userForSharedNode: { nodeHandle in
                guard let node = api.node(forHandle: nodeHandle) else { return nil }
                guard let user = api.userFrom(inShare: node) else { return nil }
                let base64Handle = MEGASdk.base64Handle(forUserHandle: user.handle)
                return UserSDKEntity(with: user, base64Handle: base64Handle)
            }
        )
    }
}
