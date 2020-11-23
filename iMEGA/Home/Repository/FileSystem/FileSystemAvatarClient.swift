import Foundation

struct FileSystemAvatarClient {

    /// Will load avatar `UIImage` from specified file path if exists, or `nil` otherwise.
    var loadUserAvatar: (
        _ avatarFilePath: String
    ) -> Data?
}

extension FileSystemAvatarClient {

    static var live: Self {
        let fileManager = FileManager.default

        return Self { [weak fileManager] avatarFilePath -> Data? in
            guard fileManager?.fileExists(atPath: avatarFilePath) == true else {
                return nil
            }
            return UIImage(contentsOfFile: avatarFilePath)?.pngData()
        }
    }
}
