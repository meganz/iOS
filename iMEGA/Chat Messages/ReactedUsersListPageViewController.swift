
import UIKit

protocol ReactedUsersListPageViewControllerDelegate: class {
    func userHandleList(atIndex index: Int) -> [UInt64]
    func pageChanged(toIndex index: Int)
}

class ReactedUsersListPageViewController: UIPageViewController {
    var pages: [MessageOptionItemsTableViewController] = []
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
        pages = (0..<numberOfPages).map { _ in MessageOptionItemsTableViewController() }
        dataSource = self
        delegate = self
        
        let reactedUsersTableViewController = pages[selectedPage]
        reactedUsersTableViewController.messageOptionItemsDataSource = self
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
        reactedUsersTableViewController.messageOptionItemsDataSource = self
        
        setViewControllers([reactedUsersTableViewController],
                           direction: index > currentIndex ? .forward : .reverse,
                           animated: true, completion: nil)
        currentIndex = index
    }
}

extension ReactedUsersListPageViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let currentVC = viewController as? MessageOptionItemsTableViewController else {
            return nil
        }
                
        if let foundIndex = pages.firstIndex(of: currentVC),
            foundIndex > 0 {
            pages[foundIndex - 1].messageOptionItemsDataSource = self
            return pages[foundIndex - 1]
        }
        
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentVC = viewController as? MessageOptionItemsTableViewController else {
            return nil
        }
        
        if let foundIndex = pages.firstIndex(of: currentVC),
            foundIndex < (pages.count - 1) {
            pages[foundIndex + 1].messageOptionItemsDataSource = self
            return pages[foundIndex + 1]
        }
        
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool, previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        guard completed,
            let currentVC = viewControllers?.first as? MessageOptionItemsTableViewController,
            let foundIndex = pages.firstIndex(of: currentVC) else {
            return
        }
        
        currentIndex = foundIndex
    }
}

extension ReactedUsersListPageViewController: MessageOptionItemsTableViewControllerDataSource {
    func numberOfItems(forViewController viewController: MessageOptionItemsTableViewController) -> Int {
        guard let controllerIndex = pages.firstIndex(of: viewController),
            let userHandleList = usersListDelegate?.userHandleList(atIndex: controllerIndex) else {
            return 0
        }
        
        return userHandleList.count
    }
    
    func setImageView(_ imageView: UIImageView, forIndex index: Int, viewController: MessageOptionItemsTableViewController) {
        guard let controllerIndex = pages.firstIndex(of: viewController),
            let userHandleList = usersListDelegate?.userHandleList(atIndex: controllerIndex) else {
            return
        }
        
        imageView.mnz_setImageAvatarOrColor(forUserHandle: userHandleList[index])
    }
    
    func setLabel(_ label: UILabel, forIndex index: Int, viewController: MessageOptionItemsTableViewController) {
        guard let controllerIndex = pages.firstIndex(of: viewController),
            let userHandleList = usersListDelegate?.userHandleList(atIndex: controllerIndex) else {
            return
        }
        
        let user = MEGAStore.shareInstance()?.fetchUser(withUserHandle: userHandleList[index])
        label.text = user?.displayName
    }
}
