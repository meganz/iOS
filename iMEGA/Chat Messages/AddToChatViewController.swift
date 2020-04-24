
import UIKit

class AddToChatViewController: UIViewController {
    
    // MARK:- Properties.

    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var contentViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentViewTrailingConstraint: NSLayoutConstraint!

    @IBOutlet weak var mediaCollectionView: UICollectionView!
    @IBOutlet weak var menuView: UIView!
    
    var tapHandler: (() -> Void)?
    var dismissHandler: ((AddToChatViewController) -> Void)?
    private var presentAndDismissAnimationDuration: TimeInterval = 0.4
    private var mediaCollectionSource: AddToChatMediaCollectionSource!
    private var menuPageViewController: UIPageViewController!

    var menuPages: [AddToChatMenuViewController]!
    
    // MARK:- View lifecycle methods.

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mediaCollectionSource = AddToChatMediaCollectionSource(collectionView: mediaCollectionView)
        setUpMenuPageViewController()
    }
    
    func setUpMenuPageViewController() {
        let firstPageController = AddToChatMenuViewController(nibName: nil, bundle: nil)
        let secondPageController = AddToChatMenuViewController(nibName: nil, bundle: nil)
        if let menus = AddToChatMenu.menus() {
            firstPageController.menus = (0..<8).map { menus[$0] }
            secondPageController.menus = [menus[8]]
        }
        menuPages = [firstPageController, secondPageController]
        
        menuPageViewController = UIPageViewController(transitionStyle: .scroll,
                                                      navigationOrientation: .horizontal,
                                                      options: nil)
        menuPageViewController.dataSource = self
        menuPageViewController.delegate = self
        addChild(menuPageViewController)
        menuView.addSubview(menuPageViewController.view)
        menuPageViewController.view.autoPinEdgesToSuperviewEdges()
        menuPageViewController.didMove(toParent: self)
        
        menuPageViewController.setViewControllers([firstPageController],
                                                  direction: .forward,
                                                  animated: false,
                                                  completion: nil)
    }
    
    // MARK:- Actions.

    @IBAction func backgroundViewTapped(_ tapGesture: UITapGestureRecognizer) {
        guard let dismissHandler = dismissHandler,
            let tapHandler = tapHandler else {
            return
        }
        
        tapHandler()
        dismissAnimation { _ in
            dismissHandler(self)
        }
    }
    
    // MARK:- Animation methods while presenting and dismissing.
    
    func presentAnimation() {
        backgroundView.alpha = 0.0
        contentViewBottomConstraint.constant = -contentViewHeightConstraint.constant
        view.layoutIfNeeded()

        UIView.animate(withDuration: presentAndDismissAnimationDuration) {
            self.backgroundView.alpha = 1.0
            self.contentViewBottomConstraint.constant = 0.0
            self.view.layoutIfNeeded()
        }
    }

    func dismissAnimation(completion: ((Bool) -> Void)?) {
        UIView.animate(withDuration: presentAndDismissAnimationDuration,
                       animations: {
                        self.backgroundView.alpha = 0.0
                        self.contentViewBottomConstraint.constant = -self.contentViewHeightConstraint.constant
                        self.view.layoutIfNeeded()
        }, completion: completion)
    }
}


extension AddToChatViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let menuViewController = viewController as? AddToChatMenuViewController,
            let index = menuPages.firstIndex(of: menuViewController),
            (index + 1) == menuPages.count else {
            return nil
        }
        
        return menuPages[index - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let menuViewController = viewController as? AddToChatMenuViewController,
            let index = menuPages.firstIndex(of: menuViewController),
            index == 0 else {
                return nil
        }
        
        return menuPages[index + 1]
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return menuPages.count
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
}
