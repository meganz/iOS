import MEGADesignToken
import MEGAPresentation
import UIKit

final class PhotosPageViewController: UIPageViewController {
    @Published var pageOffset: CGFloat = 0
    @Published var currentPage: PhotoLibraryTab = .timeline
    
    var canScroll = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scrollView = view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView
        scrollView?.delegate = self
        
        let backgroundColor = TokenColors.Background.page 
        view.backgroundColor = backgroundColor
    }
}

extension PhotosPageViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let index: Double = Double(currentPage.index)
        
        guard canScroll else {
            pageOffset = index * view.bounds.size.width / 2
            
            return
        }
        
        let diff = scrollView.contentOffset.x - view.bounds.size.width
        
        guard diff != 0 else { return }
        
        if currentPage.index == 0 {
            if diff < 0 {
                return
            } else {
                pageOffset = diff / 2
            }
        } else {
            if diff < 0 {
                let halfWidth = view.bounds.size.width / 2
                pageOffset = halfWidth - abs(diff) / 2
            } else {
                return
            }
        }
    }
}
