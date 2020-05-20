
import UIKit

class AddToChatImageCell: UICollectionViewCell {
    
    enum CellType {
        case media
        case more
    }
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var foregroundView: UIView!
    @IBOutlet weak var selectionBackgroundView: UIView!
    @IBOutlet weak var blurView: UIVisualEffectView!

    @IBOutlet weak var foregroundImageView: UIImageView!
    @IBOutlet weak var foregoundLabel: UILabel!

    
    private var imageRequestID: PHImageRequestID?
    
    var cellType: CellType = .media {
        didSet {
            if cellType == .media {
                foregoundLabel.text = AMLocalizedString("Send")
                let sendImage = UIImage(named: "sendChatDisabled")?.withRenderingMode(.alwaysTemplate)
                foregroundImageView.image = sendImage
            } else {
                foregoundLabel.text = AMLocalizedString("more")
                let moreImage = UIImage(named: "moreSelected")?.withRenderingMode(.alwaysTemplate)
                foregroundImageView.image = moreImage
                selectionBackgroundView.isHidden = true
                foregroundView.isHidden = false
                blurView.isHidden = false
            }
        }
    }
    
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
        foregroundView.isHidden = true
        selectionBackgroundView.isHidden = false
        blurView.isHidden = true
        
        if let imageRequestID = imageRequestID {
            PHImageManager.default().cancelImageRequest(imageRequestID)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        cellType = .media
    }
    
    func toggleSelection() {
        let animationDuration = 0.2
        
        if foregroundView.isHidden {
            foregroundView.alpha = 0.0
            foregroundView.isHidden = false
            UIView.animate(withDuration: animationDuration) {
                self.foregroundView.alpha = 1.0
            }
        } else {
            UIView.animate(withDuration: animationDuration,
                           animations: {
                            self.foregroundView.alpha = 0.0
            }) { _ in
                self.foregroundView.isHidden = true
                self.foregroundView.alpha = 1.0
            }
        }
    }

}
