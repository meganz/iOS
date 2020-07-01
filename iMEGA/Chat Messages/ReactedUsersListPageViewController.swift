
import UIKit

protocol ReactedUsersListPageViewControllerDelegate: class {
    func userHandleList(atIndex index: Int) -> [UInt64]
    func pageChanged(toIndex index: Int)
}

class ReactedUsersListPageViewController: UIPageViewController {
    var pages: [ReactedUsersTableViewController] = []
    var numberOfPages: Int = 0
    var currentIndex = 0 {
        didSet {
            usersListDelegate?.pageChanged(toIndex: currentIndex)
        }
    }
    
    weak var usersListDelegate: ReactedUsersListPageViewControllerDelegate?
    
    var tableViewController: UITableViewController? {
        guard pages.count <= currentIndex else {
            return nil
        }
        
        return pages[currentIndex]
    }
    
    func set(numberOfPages: Int, selectedPage: Int, initialUserHandleList: [UInt64]) {
        pages = (0..<numberOfPages).map { _ in ReactedUsersTableViewController() }
        dataSource = self
        delegate = self
        
        let reactedUsersTableViewController = pages[selectedPage]
        reactedUsersTableViewController.userHandleList = initialUserHandleList
        
        setViewControllers([reactedUsersTableViewController],
                           direction: .forward,
                           animated: false,
                           completion: nil)

    }
    
    func didSelectPage(withIndex index: Int, userHandleList: [UInt64]) {
        guard index < pages.count else {
            return
        }
        
        let reactedUsersTableViewController = pages[index]
        reactedUsersTableViewController.userHandleList = userHandleList
        
        setViewControllers([reactedUsersTableViewController],
                           direction: index > currentIndex ? .forward : .reverse,
                           animated: true, completion: nil)
        currentIndex = index
    }
}

extension ReactedUsersListPageViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let currentVC = viewController as? ReactedUsersTableViewController else {
            return nil
        }
                
        if let foundIndex = pages.firstIndex(of: currentVC),
            foundIndex > 0 {
            pages[foundIndex - 1].userHandleList = usersListDelegate?.userHandleList(atIndex: foundIndex - 1)
            return pages[foundIndex - 1]
        }
        
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentVC = viewController as? ReactedUsersTableViewController else {
            return nil
        }
        
        if let foundIndex = pages.firstIndex(of: currentVC),
            foundIndex < (pages.count - 1) {
            pages[foundIndex + 1].userHandleList = usersListDelegate?.userHandleList(atIndex: foundIndex + 1)
            return pages[foundIndex + 1]
        }
        
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool, previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        guard completed,
            let currentVC = viewControllers?.first as? ReactedUsersTableViewController,
            let foundIndex = pages.firstIndex(of: currentVC) else {
            return
        }
        
        currentIndex = foundIndex
    }
    
}
