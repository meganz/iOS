@testable import MEGA

extension FileSystemImageCacheClient {
    static var foundNil: Self {
        return Self.init { (_) -> Bool in
            return false
        } cachedImage: { (_) -> Data? in
            return nil
        } loadCachedImageAsync: { (_, _) in

        }
    }
}
