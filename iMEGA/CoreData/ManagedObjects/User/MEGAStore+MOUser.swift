
import Foundation

extension MEGAStore {
    @objc func updateUser(handle: UInt64, interactedWith: Bool) {
        if let moUser = fetchUser(withUserHandle: handle) {
            moUser.interactedwith = NSNumber.init(value: interactedWith)
            
            MEGAStore.shareInstance()?.save(storeStack.viewContext)
        }
    }
    
    @objc func updateUser(email: String, interactedWith: Bool) {
        if let moUser = fetchUser(withEmail: email) {
            moUser.interactedwith = NSNumber.init(value: interactedWith)
            
            MEGAStore.shareInstance()?.save(storeStack.viewContext)
        }
    }
}
