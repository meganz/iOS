import Foundation

struct MEGAAvatarBackgroundClient {

    var avatarBackgroundColorHex: (MEGAHandle) -> String?
}

extension MEGAAvatarBackgroundClient {

    static var live: Self {
        return Self(avatarBackgroundColorHex: { userHandle -> String? in
            MEGASdk.avatarColor(forBase64UserHandle: MEGASdk.base64Handle(forUserHandle: userHandle))
        })
    }
}
