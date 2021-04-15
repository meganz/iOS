import Foundation

extension MEGAStore {
    func updateUserNicknames(by names:[(handle: MEGAHandle, nickname: String)]) {
        guard let context = stack.newBackgroundContext() else { return }
        
        context.performAndWait {
            for name in names {
                if let user = fetchUser(withUserHandle: name.handle, context: context), user.nickname != name.nickname {
                    user.nickname = name.nickname
                }
            }
            
            save(context)
        }
    }
}
