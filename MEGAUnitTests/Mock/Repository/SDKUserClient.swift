@testable import MEGA

extension SDKUserClient {

    static var foundNil: Self {
        return Self.init(currentUser: {
            return nil
        }, userForSharedNode: { _ in
            return nil
        })
    }

    static var foundUser: Self {
        return Self(currentUser: {
            return UserDomain.mockUser
        }, userForSharedNode: { _ in
            return UserDomain.mockUser
        })
    }
}

extension UserDomain {

    static var mockUser: Self {
        return UserDomain(emai: "user@mock.com",
                          handle: UInt64(),
                          base64Handle: "",
                          change: nil,
                          contact: nil)
    }
}
