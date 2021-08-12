@testable import MEGA

extension SDKUserClient {

    static var foundNil: Self {
        return Self.init(currentUser: {
            return nil
        }, isLoggedIn: {
            false
        }, userForSharedNode: { _ in
            return nil
        }, isGuest: {
            false
        })
    }

    static var foundUser: Self {
        return Self(currentUser: {
            return UserSDKEntity.mockUser
        }, isLoggedIn: {
            false
        }, userForSharedNode: { _ in
            return UserSDKEntity.mockUser
        }, isGuest: {
            false
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
