
import UIKit

class AddToChatImageCell: UICollectionViewCell {
    
    enum CellType {
        case media
        case more
    }
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var selectedView: UIView!
    @IBOutlet weak var selectionBackgroundView: UIView!
    @IBOutlet weak var selectedImageView: UIImageView!
    @IBOutlet weak var selectedLabel: UILabel!

    
    private var imageRequestID: PHImageRequestID?
    
    var cellType: CellType = .media {
        didSet {
            if cellType == .media {
                selectedLabel.text = AMLocalizedString("Send")
                let sendImage = UIImage(named: "sendChatDisabled")?.withRenderingMode(.alwaysTemplate)
                selectedImageView.image = sendImage
            } else {
                selectedLabel.text = AMLocalizedString("more")
                let moreImage = UIImage(named: "moreSelected")?.withRenderingMode(.alwaysTemplate)
                selectedImageView.image = moreImage
                selectionBackgroundView.isHidden = true
                selectedView.isHidden = false
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
        selectedView.isHidden = true
        selectionBackgroundView.isHidden = false
        
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
