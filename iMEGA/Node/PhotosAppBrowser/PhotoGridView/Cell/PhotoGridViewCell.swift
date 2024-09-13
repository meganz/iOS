import MEGADesignToken
import Photos
import UIKit

final class PhotoGridViewCell: UICollectionViewCell {
    
    // MARK: - Outlets.
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var markerView: PhotoSelectedMarkerView!
    @IBOutlet weak var bottomView: PhotoCollectionBottomView!
    @IBOutlet weak var markerViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomViewBottomConstraint: NSLayoutConstraint!

    // MARK: - Instance variables.

    var asset: PHAsset?
    var tapHandler: ((PhotoGridViewCell, CGSize, CGPoint) -> Void)?
    var panSelectionHandler: ((Bool, PHAsset) -> Int?)?
    var assetDownloader: AssetDownloader?
    var selectedIndex: Int? {
        didSet {
            let isSelected = selectedIndex != nil
            markerView?.selected = isSelected
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

    // MARK: - Overriden methods.
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        relayoutSubViews()
    }
    
    // MARK: - Interface methods.
    
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
    
    func didEndDisplaying() {
        if assetDownloader != nil {
            assetDownloader?.cancel()
            assetDownloader = nil
        }
    }
    
    // MARK: - Private methods.
    
    @objc private func tapped(_ tapGesture: UITapGestureRecognizer) {
        if let handler = tapHandler {
            let location = tapGesture.location(in: self)
            handler(self, self.bounds.size, location)
        }
    }
    
    private func relayoutSubViews() {
        if let image = imageView.image,
            imageView.contentMode == .scaleAspectFit {
            let scaleFactor = imageView.bounds.width / image.size.width
            
            var imageHeightInView = scaleFactor * image.size.height
            imageHeightInView = imageHeightInView > imageView.bounds.height ? imageView.bounds.height : imageHeightInView
            
            let padding = (imageView.bounds.height - imageHeightInView) / 2.0
            
            markerViewTopConstraint.constant = padding
            bottomViewBottomConstraint.constant = padding
            layoutIfNeeded()
        }
    }
    
    override var isSelected: Bool {
        didSet {
            if let selectedHandler = panSelectionHandler, let asset = asset {
                selectedIndex = selectedHandler(isSelected, asset)
            }
        }
    }
    
    override func prepareForReuse() {
        asset = nil
        tapHandler = nil
        panSelectionHandler = nil
        selectedIndex = nil
        durationString = nil
        super.prepareForReuse()
    }
}
