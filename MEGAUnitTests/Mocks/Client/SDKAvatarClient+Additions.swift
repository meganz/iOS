@testable import MEGA

extension SDKAvatarClient {

    static var foundNil: Self {
        return Self(loadUserAvatar: { _, _, completion in
            completion(nil)
        }, avatarBackgroundColorHex: { _ in
            return nil
        })
    }

    static var foundImage: Self {
        return Self(loadUserAvatar: { _, _, completion in
            completion(UIImage())
        }, avatarBackgroundColorHex: { _ in
            return "#FFCCDD"
        })
    }

    static var found: (UIImage) -> Self {
        return { image in
            return Self(loadUserAvatar: { _, _, completion in
                completion(image)
            }, avatarBackgroundColorHex: { _ in
                return "#FFCCDD"
            })
        }
    }
}
