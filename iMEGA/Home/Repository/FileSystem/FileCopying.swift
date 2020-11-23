import Foundation

struct PhotoAlbumFileCopying {

    var copyImageFile: (URL) throws -> Void

    var copyVideoFile: (URL) throws -> Void
}

extension PhotoAlbumFileCopying {
    static var live: Self {
        Self(copyImageFile: { fromURL in
            if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(fromURL.path) {
                UISaveVideoAtPathToSavedPhotosAlbum(fromURL.path,
                                                    self,
                                                    #selector(video(_:didFinishSavingWithError:context:)),
                                                    nil)
            }
        }, copyVideoFile: { fromURL in

        })
    }

    @objc
    private func video(_ videoPath: String, didFinishSavingWithError error: NSError, context: UnsafeMutableRawPointer?) {

    }
}
