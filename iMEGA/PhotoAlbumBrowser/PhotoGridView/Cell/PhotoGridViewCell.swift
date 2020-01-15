
import UIKit
import Photos

class PhotoGridViewCell: UICollectionViewCell {
    
    static let reuseIdentifier = String(describing: PhotoGridViewCell.self)
    
    static var nib: UINib {
        return UINib(nibName: PhotoGridViewCell.reuseIdentifier, bundle: nil)
    }
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var markerView: PhotoSelectedMarkerView!
    @IBOutlet weak var bottomView: PhotoCollectionBottomView!
    @IBOutlet weak var markerViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomViewBottomConstraint: NSLayoutConstraint!

    var asset: PHAsset?
    var tapHandler: ((PhotoGridViewCell, CGSize, CGPoint) -> Void)?
    var assetDownloader: AssetDownloader?
    var selectedIndex: Int? {
        didSet {
            markerView.selected = (selectedIndex != nil)
            if let index = selectedIndex {
                markerView.text = "\(index + 1)"
            }
        }
    }
    
    var durationString: String? {
        didSet {
            bottomView.isHidden = (durationString == nil)
            if let durationString = durationString {
                bottomView.text = durationString
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    func willDisplay(size: CGSize) {
        guard let asset = asset,
            let imageView = imageView else {
                return
        }
        
        let assetDownloader = AssetDownloader(asset: asset, imageView: imageView, imageSize: size)
        assetDownloader.download { _ in
            self.relayoutSubViews()
        }
        
        self.assetDownloader = assetDownloader
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        relayoutSubViews()
    }
    
    private func relayoutSubViews() {
        if let image = imageView.image,
            imageView.contentMode == .scaleAspectFit {
            let scaleFactor = imageView.bounds.width / image.size.width
            
            var imageHeightInView = scaleFactor * image.size.height
            imageHeightInView = imageHeightInView > imageView.bounds.height ? imageView.bounds.height : imageHeightInView
            
            let padding = (imageView.bounds.height - imageHeightInView) / 2.0
            
            self.markerViewTopConstraint.constant = padding
            self.bottomViewBottomConstraint.constant = padding
            self.layoutIfNeeded()
        }
    }
    
    func didEndDisplaying() {
        if self.assetDownloader != nil {
            self.assetDownloader?.cancel()
            self.assetDownloader = nil
        }
    }
    
    @objc func tapped(_ tapGesture: UITapGestureRecognizer) {
        if let handler = tapHandler {
            let location = tapGesture.location(in: self)
            handler(self, self.bounds.size, location)
        }
    }
}
