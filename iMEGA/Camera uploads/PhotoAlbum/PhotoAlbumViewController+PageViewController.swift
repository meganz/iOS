import UIKit

@available(iOS 14.0, *)
extension PhotoAlbumContainerViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let page = page(of: viewController)
        
        if page == .timeline {
            return nil
        } else {
            return self.showViewController(at: .timeline)
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let vc = pageViewController.viewControllers?.first
        let page = page(of: vc)
        
        if page == .album {
            return nil
        } else {
            return self.showViewController(at: .album)
        }
    }
}

@available(iOS 14.0, *)
extension PhotoAlbumContainerViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        guard let vc = pageViewController.viewControllers?.first else { return }
        
        let page = page(of: vc)
        updateCurrentPage(page)
    }
}
