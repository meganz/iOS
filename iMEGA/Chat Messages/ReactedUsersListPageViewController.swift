
import UIKit

protocol ReactedUsersListPageViewControllerDelegate: AnyObject {
    func userHandleList(atIndex index: Int) -> [UInt64]
    func pageChanged(toIndex index: Int)
    func didSelectUserhandle(_ userhandle: UInt64)
    func userName(forHandle handle: UInt64) -> String?
}

class ReactedUsersListPageViewController: UIPageViewController {
    var pages: [ChatMessageOptionsTableViewController] = []
    var numberOfPages: Int = 0
    var currentIndex = 0 {
        didSet {
            usersListDelegate?.pageChanged(toIndex: currentIndex)
        }
    }
    
    weak var usersListDelegate: (any ReactedUsersListPageViewControllerDelegate)?
    
    var tableViewController: UITableViewController? {
        guard pages.count > currentIndex else {
            return nil
        }
        
        return pages[currentIndex]
    }
    
    func set(numberOfPages: Int, selectedPage: Int, initialUserHandleList: [UInt64]) {
        pages = (0..<numberOfPages).map { _ in ChatMessageOptionsTableViewController(chatMessageOptionDataSource: self) }
        dataSource = self
        delegate = self
        
        let reactedUsersTableViewController = pages[selectedPage]
        currentIndex = selectedPage
        reactedUsersTableViewController.chatMessageOptionDataSource = self
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
        reactedUsersTableViewController.chatMessageOptionDataSource = self
        
        setViewControllers([reactedUsersTableViewController],
                           direction: index > currentIndex ? .forward : .reverse,
                           animated: true, completion: nil)
        currentIndex = index
    }
}

extension ReactedUsersListPageViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let currentVC = viewController as? ChatMessageOptionsTableViewController else {
            return nil
        }
                
        if let foundIndex = pages.firstIndex(of: currentVC),
            foundIndex > 0 {
            return pages[foundIndex - 1]
        }
        
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentVC = viewController as? ChatMessageOptionsTableViewController else {
            return nil
        }
        
        if let foundIndex = pages.firstIndex(of: currentVC),
            foundIndex < (pages.count - 1) {
            return pages[foundIndex + 1]
        }
        
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool, previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        guard completed,
            let currentVC = viewControllers?.first as? ChatMessageOptionsTableViewController,
            let foundIndex = pages.firstIndex(of: currentVC) else {
            return
        }
        
        currentIndex = foundIndex
    }
}

extension ReactedUsersListPageViewController: ChatMessageOptionsTableViewControllerDataSource {
    func headerViewHeight() -> CGFloat {
        return 0.0
    }
    
    func headerView() -> UIView? {
        return nil
    }
    
    func numberOfItems(forViewController viewController: ChatMessageOptionsTableViewController) -> Int {
        guard let controllerIndex = pages.firstIndex(of: viewController),
            let userHandleList = usersListDelegate?.userHandleList(atIndex: controllerIndex) else {
            return 0
        }
        
        return userHandleList.count
    }
    
    func setImageView(_ imageView: UIImageView, forIndex index: Int, viewController: ChatMessageOptionsTableViewController) {
        guard let controllerIndex = pages.firstIndex(of: viewController),
            let userHandleList = usersListDelegate?.userHandleList(atIndex: controllerIndex) else {
            return
        }
        
        imageView.mnz_setImage(forUserHandle: userHandleList[index])
    }
    
    func setLabel(_ label: UILabel, forIndex index: Int, viewController: ChatMessageOptionsTableViewController) {
        guard let controllerIndex = pages.firstIndex(of: viewController),
            let userHandleList = usersListDelegate?.userHandleList(atIndex: controllerIndex) else {
            return
        }
        
        label.text = usersListDelegate?.userName(forHandle: userHandleList[index])
    }
    
    func didSelect(cellAtIndex index: Int, viewController: ChatMessageOptionsTableViewController) {
        guard let controllerIndex = pages.firstIndex(of: viewController),
            let userHandleList = usersListDelegate?.userHandleList(atIndex: controllerIndex) else {
            return
        }

        usersListDelegate?.didSelectUserhandle(userHandleList[index])
    }
}
