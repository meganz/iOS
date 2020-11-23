@testable import MEGA

extension FileSystemAvatarClient {

    static var foundNil: Self {
        return Self { _ in
            return nil
        }
    }

    static var foundAnImage: Self {
        return Self { avatarFilePath -> UIImage? in
            return UIImage()
        }
    }

    static var found: (UIImage) -> Self {
        return { image in
            return Self { _ in
                return image
            }
        }
    }
}
