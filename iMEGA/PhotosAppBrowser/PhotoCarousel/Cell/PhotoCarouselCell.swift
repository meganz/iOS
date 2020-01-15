
import UIKit
import Photos

class PhotoCarouselCell: UICollectionViewCell {

    static let reuseIdentifier = String(describing: PhotoCarouselCell.self)
    static var nib: UINib {
        return UINib(nibName: PhotoCarouselCell.reuseIdentifier, bundle: nil)
    }
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var markerView: PhotoSelectedMarkerView!
    @IBOutlet weak var playIconView: PhotoCarouselVideoIcon!
    @IBOutlet weak var videoDurationView: UIView!
    @IBOutlet weak var videoDurationLabel: UILabel!
    @IBOutlet weak var markerViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var videoDurationViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var videoDurationViewLeadingConstraint: NSLayoutConstraint!

    private let videoDurationLabelPadding: CGFloat = 5.0

    var asset: PHAsset?
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
            playIconView.isHidden = (durationString == nil)
            videoDurationView.isHidden = (durationString == nil)
            
            if let durationString = durationString {
                videoDurationLabel.text = durationString
            }
        }
    }
    
    func willDisplay(size: CGSize) {
        guard let asset = asset,
            let imageView = imageView else {
                return
        }
        
        let assetDownloader = AssetDownloader(asset: asset,
                                              imageView: imageView,
                                              imageSize: size)
        assetDownloader.download { [weak self] _ in
            self?.updateSubviewsConstraints()
        }
        
        self.assetDownloader = assetDownloader
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateImageViewConstraints()
        updateSubviewsConstraints()
    }
    
    func didEndDisplaying() {
        cancelDownloadRequest()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        cancelDownloadRequest()
        markerViewTopConstraint.constant = 0
        videoDurationViewBottomConstraint.constant = 0
    }
    
    private func cancelDownloadRequest() {
        if self.assetDownloader != nil {
            self.assetDownloader?.cancel()
            self.assetDownloader = nil
        }
    }
    
    private func updateImageViewConstraints() {
        self.imageViewWidthConstraint.constant = cellUserDisplaySize.width
        self.imageViewHeightConstraint.constant = cellUserDisplaySize.height
        imageView.layoutIfNeeded()
    }
    
    private func updateSubviewsConstraints() {
        guard let imageSize = imageView.image?.size else {
            return
        }
        
        let imageFrame = AVMakeRect(aspectRatio: imageSize,
                                    insideRect: CGRect(origin: .zero, size: cellUserDisplaySize))
        
        markerViewTopConstraint.constant = imageFrame.minY
        videoDurationViewBottomConstraint.constant = imageFrame.minY + videoDurationLabelPadding
        videoDurationViewLeadingConstraint.constant = imageFrame.minX + videoDurationLabelPadding
        layoutIfNeeded()
    }
    
    private var cellUserDisplaySize: CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: bounds.height)
    }
}
