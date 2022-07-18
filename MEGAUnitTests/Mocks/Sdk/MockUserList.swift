import Foundation
@testable import MEGA

final class MockUserList: MEGAUserList {
    private let users: [MEGAUser]
    
    init(users: [MEGAUser] = []) {
        self.users = users
        super.init()
    }
    
    override var size: NSNumber! {
        NSNumber(value: users.count)
    }
    
    override func user(at index: Int) -> MEGAUser! {
        users[index]
    }
}
