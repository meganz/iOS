
import Foundation

extension MEGAStore {
    @objc func updateUser(handle: UInt64, interactedWith: Bool) {
        if let moUser = fetchUser(withUserHandle: handle), let context = stack.viewContext {
            moUser.interactedwith = NSNumber.init(value: interactedWith)
            
            MEGAStore.shareInstance().save(context)
        }
    }
    
    @objc func updateUser(email: String, interactedWith: Bool) {
        if let moUser = fetchUser(withEmail: email), let context = stack.viewContext {
            moUser.interactedwith = NSNumber.init(value: interactedWith)
            
            MEGAStore.shareInstance().save(context)
        }
    }
}
