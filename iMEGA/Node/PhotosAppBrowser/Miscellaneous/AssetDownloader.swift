
import UIKit
import Photos

final class AssetDownloader {
    private let asset: PHAsset
    private let imageView: UIImageView
    private let imageSize: CGSize
    private let imageManager = PHCachingImageManager.default()
    private var imageRequestId: PHImageRequestID?
    
    // MARK: - Initializer.

    init(asset: PHAsset, imageView: UIImageView, imageSize: CGSize) {
        self.asset = asset
        self.imageView = imageView
        self.imageSize = imageSize
    }
    
    // MARK: - Interface methods.
    
    func download(handler: ((Bool) -> Void)?) {
        let scale = UIScreen.main.scale
        let size = CGSize(width: imageSize.width * scale,
                          height: imageSize.width * scale)
                
        let imageRequestOptions = PHImageRequestOptions()
        imageRequestOptions.isNetworkAccessAllowed = true
        
        imageRequestId = imageManager.requestImage(for: asset,
                                                   targetSize: size,
                                                   contentMode: .aspectFill,
                                                   options: imageRequestOptions) { [weak self] image, _ in
                                                    guard let image = image else {
                                                        if let handler = handler {
                                                            handler(false)
                                                        }
                                                        return
                                                    }
                                                    
                                                    self?.imageView.image = image
                                                    if let handler = handler {
                                                        handler(true)
                                                    }
        }
    }
    
    func cancel() {
        if let imageRequestId = imageRequestId {
            imageManager.cancelImageRequest(imageRequestId)
            self.imageRequestId = nil
        }
    }
}
