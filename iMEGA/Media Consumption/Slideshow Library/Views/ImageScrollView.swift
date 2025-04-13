import Foundation
import SDWebImage

final class ImageScrollView: UIScrollView {
    
    enum ScaleMode {
        case aspectFill
        case aspectFit
        case widthFill
        case heightFill
    }
    
    enum Offset {
        case begining
        case center
    }
    
    static let kZoomInFactorFromMinWhenDoubleTap: CGFloat = 5
    
    var imageContentMode: ScaleMode = .widthFill
    var initialOffset: Offset = .begining
    private(set) var zoomView: UIImageView?
    var imageSize: CGSize = CGSize.zero
    private var pointToCenterAfterResize: CGPoint = CGPoint.zero
    private var scaleToRestoreAfterResize: CGFloat = 1.0
    var maxScaleFromMinScale: CGFloat = 5.0
    
    override var frame: CGRect {
        willSet {
            if frame.equalTo(newValue) == false && newValue.equalTo(CGRect.zero) == false && imageSize.equalTo(CGSize.zero) == false {
                prepareToResize()
            }
        }
        
        didSet {
            if frame.equalTo(oldValue) == false && frame.equalTo(CGRect.zero) == false && imageSize.equalTo(CGSize.zero) == false {
                recoverFromResizing()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func initialize() {
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        bouncesZoom = true
        decelerationRate = UIScrollView.DecelerationRate.fast
        delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(ImageScrollView.changeOrientationNotification), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    func adjustFrameToCenter() {
        guard let unwrappedZoomView = zoomView else {
            return
        }
        var frameToCenter = unwrappedZoomView.frame
        
        if frameToCenter.size.width < bounds.width {
            frameToCenter.origin.x = (bounds.width - frameToCenter.size.width) / 2
        } else {
            frameToCenter.origin.x = 0
        }
        
        if frameToCenter.size.height < bounds.height {
            frameToCenter.origin.y = (bounds.height - frameToCenter.size.height) / 2
        } else {
            frameToCenter.origin.y = 0
        }
        unwrappedZoomView.frame = frameToCenter
    }
    
    private func prepareToResize() {
        let boundsCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        pointToCenterAfterResize = convert(boundsCenter, to: zoomView)
        scaleToRestoreAfterResize = zoomScale
        if scaleToRestoreAfterResize <= minimumZoomScale + CGFloat(Float.ulpOfOne) {
            scaleToRestoreAfterResize = 0
        }
    }
    
    private func recoverFromResizing() {
        setMaxMinZoomScalesForCurrentBounds()
        let maxZoomScale = max(minimumZoomScale, scaleToRestoreAfterResize)
        zoomScale = min(maximumZoomScale, maxZoomScale)
        let boundsCenter = convert(pointToCenterAfterResize, to: zoomView)
        var offset = CGPoint(x: boundsCenter.x - bounds.size.width/2.0, y: boundsCenter.y - bounds.size.height/2.0)
        let maxOffset = maximumContentOffset()
        let minOffset = minimumContentOffset()
        var realMaxOffset = min(maxOffset.x, offset.x)
        offset.x = max(minOffset.x, realMaxOffset)
        realMaxOffset = min(maxOffset.y, offset.y)
        offset.y = max(minOffset.y, realMaxOffset)
        contentOffset = offset
    }
    
    private func maximumContentOffset() -> CGPoint {
        return CGPoint(x: contentSize.width - bounds.width, y: contentSize.height - bounds.height)
    }
    
    private func minimumContentOffset() -> CGPoint {
        return CGPoint.zero
    }
    
    func display(image: UIImage, gifImageFileUrl: URL? = nil) {
        if let zoomView = zoomView {
            zoomView.removeFromSuperview()
        }
        zoomView = UIImageView(image: image)
        if let gifImageFileUrl = gifImageFileUrl {
            zoomView?.sd_setImage(with: gifImageFileUrl, placeholderImage: image)
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            configureAfterDisplay()
            configureImageForSize(image.size)
            adjustFrameToCenter()
            setNeedsDisplay()
        }
    }
    
    private func configureAfterDisplay() {
        guard let zoomView = zoomView else { return }
        
        zoomView.isUserInteractionEnabled = true
        addSubview(zoomView)
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(ImageScrollView.doubleTapGestureRecognizer(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        zoomView.addGestureRecognizer(doubleTapGesture)
    }
    
    private func configureImageForSize(_ size: CGSize) {
        imageSize = size
        contentSize = imageSize
        setMaxMinZoomScalesForCurrentBounds()
        zoomScale = minimumZoomScale
        switch initialOffset {
        case .begining:
            contentOffset =  CGPoint.zero
        case .center:
            let xOffset = contentSize.width < bounds.width ? 0 : (contentSize.width - bounds.width)/2
            let yOffset = contentSize.height < bounds.height ? 0 : (contentSize.height - bounds.height)/2
            switch imageContentMode {
            case .aspectFit:
                contentOffset =  CGPoint.zero
            case .aspectFill:
                contentOffset = CGPoint(x: xOffset, y: yOffset)
            case .heightFill:
                contentOffset = CGPoint(x: xOffset, y: 0)
            case .widthFill:
                contentOffset = CGPoint(x: 0, y: yOffset)
            }
        }
    }
    
    private func setMaxMinZoomScalesForCurrentBounds() {
        let xScale = bounds.width / imageSize.width
        let yScale = bounds.height / imageSize.height
        var minScale: CGFloat = 1
        
        switch imageContentMode {
        case .aspectFill:
            minScale = max(xScale, yScale)
        case .aspectFit:
            minScale = min(xScale, yScale)
        case .widthFill:
            minScale = xScale
        case .heightFill:
            minScale = yScale
        }
        let maxScale = maxScaleFromMinScale*minScale
        if minScale > maxScale {
            minScale = maxScale
        }
        maximumZoomScale = maxScale
        minimumZoomScale = minScale * 0.999
    }
    
    @objc func doubleTapGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        if zoomScale >= minimumZoomScale * ImageScrollView.kZoomInFactorFromMinWhenDoubleTap - 0.01 {
            resetZoomScale(animated: true)
        } else {
            let center = gestureRecognizer.location(in: gestureRecognizer.view)
            let zoomRect = zoomRectForScale(ImageScrollView.kZoomInFactorFromMinWhenDoubleTap * minimumZoomScale, center: center)
            zoom(to: zoomRect, animated: true)
        }
    }
    
    func resetZoomScale(animated: Bool = false) {
        setZoomScale(minimumZoomScale, animated: animated)
    }
    
    private func zoomRectForScale(_ scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = frame.size.height / scale
        zoomRect.size.width  = frame.size.width  / scale
        zoomRect.origin.x    = center.x - (zoomRect.size.width  / 2.0)
        zoomRect.origin.y    = center.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }
    
    private func updateUIForOrientationChange() {
        adjustFrameToCenter()
        configureImageForSize(imageSize)
        setNeedsDisplay()
    }
    
    @objc func changeOrientationNotification() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.updateUIForOrientationChange()
        }
    }
}

extension ImageScrollView: UIScrollViewDelegate {
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return false
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return zoomView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        adjustFrameToCenter()
    }
}
