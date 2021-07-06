@testable import MEGA

extension StoreUserClient {

    static var foundNil: Self {
        return Self { _ in
            return nil
        }
    }

    static var foundAUser: Self {
        return Self { _ in
            StoreUser.mockUser
        }
    }
}
