import Foundation

struct FileSystemAvatarClient {

    var loadUserAvatar: (String) -> UIImage?
}

extension FileSystemAvatarClient {

    static var live: Self {
        let fileManager = FileManager.default

        return Self { [weak fileManager] avatarFilePath -> UIImage? in
            guard fileManager?.fileExists(atPath: avatarFilePath) == true else {
                return nil
            }
            return UIImage(contentsOfFile: avatarFilePath)
        }
    }
}
