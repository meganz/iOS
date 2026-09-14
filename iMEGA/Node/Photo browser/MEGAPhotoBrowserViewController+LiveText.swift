import MEGADomain
import VisionKit

extension MEGAPhotoBrowserViewController {
    
    @objc func imageView(frame: CGRect) -> UIImageView {
        guard ImageAnalyzer.isSupported else {
            return SDAnimatedImageView(frame: frame)
        }
        return LiveTextImageView(frame: frame)
    }
    
    @objc func currentImageView(from imageViewCache: NSCache<NSNumber, UIScrollView>) -> UIImageView? {
        guard let cacheKey = dataProvider.currentCacheKey else { return nil }
        let zoomableView = imageViewCache.object(forKey: cacheKey)
        return zoomableView?.subviews.first as? UIImageView
    }
    
    @objc func configLiveTextInterface(from imageViewCache: NSCache<NSNumber, UIScrollView>) {
        guard let imageView = currentImageView(from: imageViewCache) else { return }
        imageView.setImageLiveTextInterfaceHidden(true)
    }
    
    @objc func startLiveTextAnalysis(from imageViewCache: NSCache<NSNumber, UIScrollView>) {
        guard let imageView = currentImageView(from: imageViewCache) else { return }
        imageView.setImageLiveTextInterfaceHidden(false)
        imageView.startImageLiveTextAnalysisIfNeeded()
    }
    
    @objc func configLiveTextLayout(from imageViewCache: NSCache<NSNumber, UIScrollView>, isInterfaceHidden: Bool, toolBarFrame: CGRect) {
        guard let imageView = currentImageView(from: imageViewCache) else { return }
        
        let isImageAndToolBarOverlapped = imageView.frame.maxY >= toolBarFrame.minY
        var contentInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        
        if isImageAndToolBarOverlapped && !isInterfaceHidden {
            let padding: CGFloat = 5.0
            contentInset.bottom = toolBarFrame.height + padding
        }

        imageView.setImageLiveTextSupplementaryInterfaceContentInsets(contentInset)
    }
    
    @objc func startLiveTextAnalysis(for imageView: UIImageView, cacheKey: NSNumber) {
        guard cacheKey == dataProvider.currentCacheKey else { return }
        imageView.startImageLiveTextAnalysisIfNeeded()
    }
}
