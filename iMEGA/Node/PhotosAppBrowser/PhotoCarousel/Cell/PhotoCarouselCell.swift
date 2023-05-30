
import UIKit
import Photos

final class PhotoCarouselCell: UICollectionViewCell {
    
    // MARK: - Outlets.
    
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
    
    // MARK: - Instance variables.

    private let videoDurationLabelPadding: CGFloat = 5.0
    private var assetDownloader: AssetDownloader?

    var asset: PHAsset?
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
    
    var didSelectMarkerHandler: ((PhotoCarouselCell) -> Void)? {
        didSet {
            guard let didSelectMarkerHandler = didSelectMarkerHandler else {
                markerView.singleTapHandler = nil
                return
            }
            
            markerView.singleTapHandler = { [weak self] in
                guard let `self` = self else { return }
                didSelectMarkerHandler(self)
            }
        }
    }
    
    var didSelectVideoIconHandler: ((PhotoCarouselCell) -> Void)? {
        didSet {
            guard let didSelectVideoIconHandler = didSelectVideoIconHandler else {
                playIconView.singleTapHandler = nil
                return
            }
            
            playIconView.singleTapHandler = { [weak self] in
                guard let `self` = self else { return }
                didSelectVideoIconHandler(self)
            }
        }
    }
    
    // MARK: - overriden methods.
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateImageViewConstraints()
        updateSubviewsConstraints()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        cancelDownloadRequest()
        markerViewTopConstraint.constant = 6
        videoDurationViewBottomConstraint.constant = 0
    }
    
    // MARK: - Interface methods.
    
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
    
    func didEndDisplaying() {
        cancelDownloadRequest()
    }
    
    // MARK: - Private methods.
    
    private func cancelDownloadRequest() {
        if assetDownloader != nil {
            assetDownloader?.cancel()
            assetDownloader = nil
        }
    }
    
    private func updateImageViewConstraints() {
        imageViewWidthConstraint.constant = cellUserDisplaySize.width
        imageViewHeightConstraint.constant = cellUserDisplaySize.height
        imageView.layoutIfNeeded()
    }
    
    private func updateSubviewsConstraints() {
        guard let imageSize = imageView.image?.size else {
            return
        }
        
        let imageFrame = AVMakeRect(aspectRatio: imageSize,
                                    insideRect: CGRect(origin: .zero, size: cellUserDisplaySize))
        
        markerViewTopConstraint.constant = imageFrame.minY + 6
        videoDurationViewBottomConstraint.constant = imageFrame.minY + videoDurationLabelPadding
        videoDurationViewLeadingConstraint.constant = imageFrame.minX + videoDurationLabelPadding
        layoutIfNeeded()
    }
    
    private var cellUserDisplaySize: CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: bounds.height)
    }
}
