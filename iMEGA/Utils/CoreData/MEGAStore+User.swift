import Foundation
import MEGADomain

extension MEGAStore {
    func updateUserNicknames(by names: [(handle: HandleEntity, nickname: String)]) {
        guard let context = stack.newBackgroundContext() else { return }
        
        context.performAndWait {
            for name in names {
                if let user = fetchUser(withUserHandle: name.handle, context: context), user.nickname != name.nickname {
                    user.nickname = name.nickname
                } else { // user does not exsist in database yet. Delegate the task to main context
                    let handle = name.handle
                    let nickname = name.nickname
                    DispatchQueue.main.async {
                        if let user = self.fetchUser(withUserHandle: handle) {
                            user.nickname = nickname
                            if let context = self.stack.viewContext {
                                self.save(context)
                            }
                        } else {
                            self.insertUser(withUserHandle: handle, firstname: nil, lastname: nil, nickname: nickname, email: nil)
                        }
                    }
                }
            }
            
            save(context)
        }
    }
    
    func insertUser(
        userHandle: HandleEntity,
        firstname: String? = nil,
        lastname: String? = nil,
        nickname: String? = nil,
        email: String? = nil
    ) {
        self.insertUser(
            withUserHandle: userHandle,
            firstname: firstname,
            lastname: lastname,
            nickname: nickname,
            email: email
        )
    }
}
