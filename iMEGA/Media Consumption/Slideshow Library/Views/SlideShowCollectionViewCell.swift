import UIKit

final class SlideShowCollectionViewCell: UICollectionViewCell {
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var imageView: UIImageView!
    
    private var slideshowInteraction: SlideShowInteraction?
    
    required init(coder aDecoder:NSCoder){
        super.init(coder: aDecoder)!
    }
        
    func update(withImage image: UIImage, andInteraction slideshowInteraction: SlideShowInteraction) {
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        
        scrollView.delegate = self
        setZoomScale()
        scrollView.contentInsetAdjustmentBehavior = .never
        
        self.slideshowInteraction = slideshowInteraction
        
        addGestures()
    }
    
    func setZoomScale() {
        scrollView.maximumZoomScale = 5.0
        scrollView.minimumZoomScale = 1.0
        scrollView.setZoomScale(scrollView.minimumZoomScale, animated: false)
    }
    
    func addGestures() {
        let doubleTap = UITapGestureRecognizer(target:self, action:#selector(doubleTap(gesture:)))
        doubleTap.numberOfTapsRequired = 2
        self.addGestureRecognizer(doubleTap)
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(singleTap))
        singleTap.numberOfTapsRequired = 1
        self.addGestureRecognizer(singleTap)
    }
    
    @objc func doubleTap(gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            let zoomRect = zoomRectForScale(scale: 1.5, center: gesture.location(in: gesture.view))
            scrollView.zoom(to: zoomRect, animated: true)
        }
    }
    
    private func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = imageView.bounds.size.height / scale
        zoomRect.size.width  = imageView.bounds.size.width  / scale
        let newCenter = scrollView.convert(center, from: self)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }
    
    @objc func singleTap(gesture: UITapGestureRecognizer) {
        slideshowInteraction?.pausePlaying()
    }
}

extension SlideShowCollectionViewCell :UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        slideshowInteraction?.pausePlaying()
    }
}
