
extension MEGAPhotoBrowserViewController {
    
    @objc func imageView(frame: CGRect) -> UIImageView {
        guard #available(iOS 16, *) else {
            return UIImageView(frame: frame)
        }
        return LiveTextImageView(frame: frame)
    }
    
    @objc func currentImageView(from imageViewCache: NSCache<NSNumber, UIScrollView>) -> UIImageView? {
        let zoomableView = imageViewCache.object(forKey: dataProvider.currentIndex as NSNumber)
        return zoomableView?.subviews.first as? UIImageView
    }
    
    @objc func configLiveTextInterface(from imageViewCache: NSCache<NSNumber, UIScrollView>) {
        guard #available(iOS 16, *), let imageView = currentImageView(from: imageViewCache) else { return }
        imageView.setImageLiveTextInterfaceHidden(true)
    }
    
    @objc func startLiveTextAnalysis(from imageViewCache: NSCache<NSNumber, UIScrollView>) {
        guard #available(iOS 16, *), let imageView = currentImageView(from: imageViewCache) else { return }
        imageView.setImageLiveTextInterfaceHidden(false)
        imageView.startImageLiveTextAnalysisIfNeeded()
    }
    
    @objc func configLiveTextLayout(from imageViewCache: NSCache<NSNumber, UIScrollView>, isInterfaceHidden: Bool, toolBarHeight: CGFloat) {
        guard #available(iOS 16, *), let imageView = currentImageView(from: imageViewCache) else { return }
        
        let isCurrentImageInFullScreen = imageView.frame.height.rounded() >= UIScreen.main.bounds.height
        var contentInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        
        if isCurrentImageInFullScreen && !isInterfaceHidden {
            let padding: CGFloat = 5.0
            contentInset.bottom = toolBarHeight + padding
        }

        imageView.setImageLiveTextSupplementaryInterfaceContentInsets(contentInset)
    }
    
    @objc func startLiveTextAnalysis(for imageView: UIImageView, in index: Int) {
        guard #available(iOS 16, *), index == dataProvider.currentIndex else { return }
        imageView.startImageLiveTextAnalysisIfNeeded()
    }
}
