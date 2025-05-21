import MEGAAssets
import MEGADesignToken
import MEGAL10n
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
    @IBOutlet weak var bottomLeftLabel: UILabel!
    @IBOutlet weak var bottomLeftView: UIView!

    private var imageRequestID: PHImageRequestID?
    
    var cellType: CellType = .media {
        didSet {
            if cellType == .media {
                foregoundLabel.text = Strings.Localizable.send
                let sendImage = MEGAAssets.UIImage.sendChatDisabled.withRenderingMode(.alwaysTemplate)
                foregroundImageView.image = sendImage
            } else {
                foregoundLabel.text = Strings.Localizable.more
                let moreImage = MEGAAssets.UIImage.moreGrid.withRenderingMode(.alwaysTemplate)
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
            
            if asset.mediaType == .video {
                bottomLeftView.isHidden = false
                
                let formatter = DateComponentsFormatter()
                
                // If the duration is more than an hour, display hour
                if asset.duration >= 3600.0 {
                    formatter.allowedUnits = [.hour, .minute, .second]
                } else {
                    formatter.allowedUnits = [.minute, .second]
                }
                
                formatter.unitsStyle = .positional
                formatter.zeroFormattingBehavior = .pad
                bottomLeftLabel.text = formatter.string(from: asset.duration)
            }
            
            let scale = UIScreen.main.scale
            let targetSize = CGSize(width: bounds.size.width * scale, height: bounds.size.height * scale)
            imageRequestID = PHCachingImageManager.default().requestImage(for: asset,
                                                                          targetSize: targetSize,
                                                                          contentMode: .aspectFill,
                                                                          options: PHImageRequestOptions(),
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
        bottomLeftView.isHidden = true
        
        if let imageRequestID = imageRequestID {
            PHCachingImageManager.default().cancelImageRequest(imageRequestID)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        cellType = .media
        imageView.backgroundColor = TokenColors.Background.page
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
            }, completion: { _ in
                self.foregroundView.isHidden = true
                self.foregroundView.alpha = 1.0
            })
        }
    }

}
