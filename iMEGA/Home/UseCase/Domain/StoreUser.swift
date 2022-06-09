import Foundation

struct StoreUser {

    let fullName: String

    let firstName: String

    let displayName: String

    let interactedWith: Bool
}

extension StoreUser {
    init(from user: MOUser) {
        self.fullName = user.fullName
        self.firstName = user.firstName ?? ""
        self.displayName = user.displayName
        self.interactedWith = user.interactedWith.boolValue
    }
}
