import Foundation

struct StoreUserClient {

    /// Will return the `StoreUser` in `Core Data` by user's handle.
    var getUser: (_ userHandle: HandleEntity) -> StoreUser?
}

extension StoreUserClient {

    static var live: Self {
        let store = MEGAStore.shareInstance()

        return Self { [weak store] userHandle in
            store?.fetchUser(withUserHandle: userHandle).map(StoreUser.init)
        }
    }
}
