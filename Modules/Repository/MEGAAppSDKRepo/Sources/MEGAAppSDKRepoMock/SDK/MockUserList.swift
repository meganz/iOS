import MEGASdk

public final class MockUserList: MEGAUserList {
    private let users: [MEGAUser]
    
    public init(users: [MEGAUser] = []) {
        self.users = users
        super.init()
    }
    
    public override var size: Int {
        users.count
    }
    
    public override func user(at index: Int) -> MEGAUser? {
        users[index]
    }
}
