import Foundation

struct FileSystemImageCacheClient {

    var fileExists: (
        _ filePathURL: URL
    ) -> Bool

    var cachedImage: (
        _ filePathURL: URL
    ) -> Data?

    var loadCachedImageAsync: (
        _ filePathURL: URL,
        _ foundCachedImageCompletion: @escaping (Data?) -> Void
    ) -> Void
}

extension FileSystemImageCacheClient {

    static var live: Self {
        let fileManager = FileManager.default

        return Self.init(
            fileExists: { filePathURL in
                let filePath = filePathURL.path
                return fileManager.fileExists(atPath: filePath)
            },

            cachedImage: { filePathURL -> Data? in
                let filePath = filePathURL.path
                guard fileManager.fileExists(atPath: filePath) == true else {
                    return nil
                }
                return UIImage(contentsOfFile: filePath)?.pngData()
            },

            loadCachedImageAsync: { filePathURL, foundCachedImageCompletion in
                let filePath = filePathURL.path
                guard fileManager.fileExists(atPath: filePath) == true else {
                    asyncOnGlobal { foundCachedImageCompletion(nil) }
                    return
                }
                asyncOnGlobal {
                    foundCachedImageCompletion(UIImage(contentsOfFile: filePath)?.pngData())
                }
            }
        )
    }
}
