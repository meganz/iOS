@testable import MEGA

extension StoreUser {

    static var mockUser: Self {
        return StoreUser(fullName: "Mock Name", firstName: "Mock", displayName: "Mr. Mock", interactedWith: false)
    }
}
