
import UIKit
import Photos

final class AlbumTableViewCell: UITableViewCell {
    
    @IBOutlet var albumImageViews: [UIImageView]!
    @IBOutlet weak var albumTitleLabel: UILabel!
    @IBOutlet weak var albumPhotosCount: UILabel!
    
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private var assetDownloaders: [AssetDownloader] = []
    
    var album: Album? {
        didSet {
            albumTitleLabel.text = album?.title
            let assetCount = album?.assetCount() ?? 0
            albumPhotosCount.text = "\(assetCount)"
        }
    }
    
    // MARK:- Interface methods.
    
    func displayPreviewImages() {
        guard let album = album else {
            return
        }
        
        showImageDownloadInProgress()
        cancelPendingRequests()
        let assets = album.assets(count: albumImageViews.count)
        
        assets.enumerated().forEach { [weak self] index, asset in
            let imageView = albumImageViews[index]
            let assetDownloader = AssetDownloader(asset: asset,
                                                  imageView: imageView,
                                                  imageSize: imageView.frame.size)
            assetDownloader.download { _ in
                if index == 0 {
                    self?.hideImageDownloadInProgress()
                }
            }
            
            assetDownloaders.append(assetDownloader)
        }
    }
    
    func cancelPreviewImagesLoading() {
        cancelPendingRequests()
    }
    
    func cancelPendingRequests() {
        if assetDownloaders.isEmpty {
            return
        }
        
        assetDownloaders.forEach { assetDownloader in
            assetDownloader.cancel()
        }
        assetDownloaders = []
    }
    
    // MARK:- Overriden methods.
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        cancelPendingRequests()
        albumImageViews.forEach { imageView in
            imageView.image = nil
        }
    }
}

// MARK:- Show and Hide Activity Indicator methods.

extension AlbumTableViewCell {
    private func showImageDownloadInProgress() {
        if let imageView = albumImageViews.first,
            imageView.subviews.contains(activityIndicator) == false {
            
            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
            activityIndicator.startAnimating()
            imageView.addSubview(activityIndicator)
            
            activityIndicator.centerXAnchor.constraint(equalTo: imageView.centerXAnchor).isActive = true
            activityIndicator.centerYAnchor.constraint(equalTo: imageView.centerYAnchor).isActive = true
        }
    }
    
    private func hideImageDownloadInProgress() {
        if let imageView = albumImageViews.first,
            imageView.subviews.contains(activityIndicator) {
            activityIndicator.removeFromSuperview()
        }
    }
}
