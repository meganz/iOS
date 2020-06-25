
import UIKit

class ReactedUsersListPageViewController: UIPageViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // TODO: Need to add the logic dependent on the number of emojis
        setViewControllers([ReactedUsersTableViewController(), ReactedUsersTableViewController()],
                           direction: .forward,
                           animated: false,
                           completion: nil)
        
        dataSource = self
        delegate = self
    }

}

extension ReactedUsersListPageViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        // TODO: Update the logic
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        // TODO: Update the logic
        return nil
    }
}
