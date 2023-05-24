import UIKit

extension UIImage {
    func shrinkedImageData(docScanQuality: DocScanQuality) -> Data? {
        let maxSize = CGFloat(docScanQuality.imageSize)
        let width = self.size.width
        let height = self.size.height
        var newWidth = width
        var newHeight = height
        if width > maxSize || height > maxSize {
            if width > height {
                newWidth = maxSize
                newHeight = (height * maxSize) / width
            } else {
                newHeight = maxSize
                newWidth = (width * maxSize) / height
            }
        }
        return self.resize(to: CGSize(width: newWidth / UIScreen.main.scale, height: newHeight / UIScreen.main.scale)).jpegData(compressionQuality: CGFloat(docScanQuality.rawValue))
    }
}
