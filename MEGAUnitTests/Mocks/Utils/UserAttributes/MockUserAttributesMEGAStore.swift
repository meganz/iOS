@testable import MEGA

public final class MockUserAttributesMEGAStore: MEGAStore, @unchecked Sendable {
    public let currentContext: NSManagedObjectContext
    
    // In-memory storage for users, using handles as keys
    private var users: [UInt64: MockMOUser] = [:]
    
    public init(currentContext: NSManagedObjectContext) {
        self.currentContext = currentContext
    }
    
    // MARK: - Fetch MockMOUser by Handle
    public override func fetchUser(withUserHandle userHandle: UInt64, context: NSManagedObjectContext) -> MOUser? {
        users[userHandle]?.toMOUser(context: currentContext)
    }
    
    public override func fetchUser(withUserHandle userHandle: UInt64) -> MOUser? {
        users[userHandle]?.toMOUser(context: currentContext)
    }
    
    public override func fetchUser(withEmail email: String) -> MOUser? {
        firstUser(withEmail: email)?.toMOUser(context: currentContext)
    }
    
    public override func insertUser(withUserHandle handle: UInt64, firstname: String?, lastname: String?, nickname: String?, email: String?) {
        let newUser = MockMOUser(firstname: firstname, lastname: lastname, nickname: nickname, email: email)
        users[handle] = newUser
    }
    
    public override func updateUser(withUserHandle handle: UInt64, firstname: String) {
        updateUser(handle: handle, updateBlock: { user in
            user.firstname = firstname
        })
    }
    
    public override func updateUser(withUserHandle handle: UInt64, lastname: String) {
        updateUser(handle: handle, updateBlock: { user in
            user.lastname = lastname
        })
    }
    
    public override func updateUser(withUserHandle handle: UInt64, nickname: String) {
        updateUser(handle: handle, updateBlock: { user in
            user.nickname = nickname
        })
    }
    
    public override func updateUser(withEmail email: String, firstname: String) {
        if let handle = handleForUser(withEmail: email) {
            updateUser(handle: handle, updateBlock: { user in
                user.firstname = firstname
            })
        }
    }
    
    public override func updateUser(withEmail email: String, lastname: String) {
        if let handle = handleForUser(withEmail: email) {
            updateUser(handle: handle, updateBlock: { user in
                user.lastname = lastname
            })
        }
    }
    
    public override func updateUser(withEmail email: String, nickname: String) {
        if let handle = handleForUser(withEmail: email) {
            updateUser(handle: handle, updateBlock: { user in
                user.nickname = nickname
            })
        }
    }
    
    func firstUser(withEmail email: String) -> MockMOUser? {
        users.values.first { $0.email == email }
    }
    
    func handleForUser(withEmail email: String) -> UInt64? {
        users.first { $0.value.email == email }?.key
    }
    
    private func updateUser(handle: UInt64, updateBlock: (inout MockMOUser) -> Void) {
        if var user = users[handle] {
            updateBlock(&user)
            users[handle] = user
        }
    }
}
