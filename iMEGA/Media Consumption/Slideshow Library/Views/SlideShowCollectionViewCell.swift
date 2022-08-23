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
        
        scrollView.delegate = self
        scrollView.maximumZoomScale = 5.0
        scrollView.minimumZoomScale = 1.0
        
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        
        self.slideshowInteraction = slideshowInteraction
        
        let doubleTap = UITapGestureRecognizer(target:self, action:#selector(doubleTap(gesture:)))
        doubleTap.numberOfTapsRequired = 2
        self.addGestureRecognizer(doubleTap)
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(singleTap))
        singleTap.numberOfTapsRequired = 1
        self.addGestureRecognizer(singleTap)
    }
    
    private func correctOrigin(forView view: UIView, scaledAt scale: CGFloat){
        var frame = view.frame
        frame.origin.x = max(frame.origin.x + (scrollView.frame.size.width - (view.frame.size.width * scale)) / 2, 0)
        frame.origin.y = max(frame.origin.y + (scrollView.frame.size.height - (view.frame.size.height * scale)) / 2, 0)
        view.frame = frame
    }
    
    @objc func doubleTap(gesture: UITapGestureRecognizer){
        var newScale: CGFloat = 0
        if imageView.frame.size.width < scrollView.frame.size.width {
            newScale = scrollView.zoomScale > 1.0 ? 1.0 : scrollView.frame.size.width / imageView.frame.size.width
        } else {
            newScale = scrollView.zoomScale > 1.0 ? 1.0 : 5.0
        }

        UIView.animate(withDuration: 0.3) {
            if newScale > 1.0 {
                var tapPoint =  gesture.location(in: self.imageView)
                tapPoint = self.imageView.convert(tapPoint, from: gesture.view)

                var zoomRect = CGRect.zero
                zoomRect.size.width = self.imageView.frame.size.width / newScale
                zoomRect.size.height = self.imageView.frame.size.height / newScale
                zoomRect.origin.x = tapPoint.x - zoomRect.size.width / 2
                zoomRect.origin.y = tapPoint.y - zoomRect.size.height / 2

                self.scrollView.zoom(to: zoomRect, animated: false)
            } else {
                self.scrollView.zoomScale = newScale
            }
            self.correctOrigin(forView: self.imageView, scaledAt: newScale)
        }
    }
    
    @objc func singleTap(gesture: UITapGestureRecognizer) {
        slideshowInteraction?.singleTapOnSlideshow()
    }
}

extension SlideShowCollectionViewCell :UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
}
