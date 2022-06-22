import UIKit

extension MEGAPhotoBrowserViewController {
    @objc func subtitle(fromDate date: Date) -> String {
        DateFormatter.fromTemplate("MMMM dd • HH:mm").localisedString(from: date)
    }
    
    @objc func freeUpSpace(onImageViewCache cache: NSCache<NSNumber, UIScrollView>, scrollView: UIScrollView) {
        SVProgressHUD.show()
        scrollView.subviews.forEach({ $0.removeFromSuperview() })
        cache.removeAllObjects()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            SVProgressHUD.dismiss()
        }
    }
    
    @objc func rootPesentingViewController() -> UIViewController? {
        var curPresentingVC = presentingViewController
        var prePesentingVC: UIViewController?
        
        while curPresentingVC != nil {
            prePesentingVC = curPresentingVC
            curPresentingVC = curPresentingVC?.presentingViewController
        }
        
        return prePesentingVC
    }
}
