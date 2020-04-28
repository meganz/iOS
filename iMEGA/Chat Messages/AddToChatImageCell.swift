
import UIKit

class AddToChatImageCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var selectedView: UIView!
    private var imageRequestID: PHImageRequestID?
    
    var asset: PHAsset! {
        didSet {
            guard let asset = asset else {
                imageView.image = nil
                return
            }
            
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = true
            
            imageRequestID = PHImageManager.default().requestImage(for: asset,
                                                                   targetSize: bounds.size,
                                                                   contentMode: .aspectFill,
                                                                   options: requestOptions,
                                                                   resultHandler: { [weak self] (image, _) in
                                                                    self?.imageView.image = image
                                                                    self?.imageRequestID = nil
            })
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        selectedView.isHidden = true
        
        if let imageRequestID = imageRequestID {
            PHImageManager.default().cancelImageRequest(imageRequestID)
        }
    }
    
    func toggleSelection() {
        let animationDuration = 0.2
        
        if selectedView.isHidden {
            selectedView.alpha = 0.0
            selectedView.isHidden = false
            UIView.animate(withDuration: animationDuration) {
                self.selectedView.alpha = 1.0
            }
        } else {
            UIView.animate(withDuration: animationDuration,
                           animations: {
                            self.selectedView.alpha = 0.0
            }) { _ in
                self.selectedView.isHidden = true
                self.selectedView.alpha = 1.0
            }
        }
    }

}
