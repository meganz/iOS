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
            return UserSDKEntity.mockUser
        }, userForSharedNode: { _ in
            return UserSDKEntity.mockUser
        })
    }
}

extension UserSDKEntity {
    static var mockUser: Self {
        return UserSDKEntity(email: "user@mock.com",
                             handle: UInt64(),
                             base64Handle: "",
                             change: nil,
                             contact: nil)
    }
}
