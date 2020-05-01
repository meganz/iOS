
import UIKit

protocol AddToChatViewControllerDelegate: class {
    func send(asset: PHAsset)
    func loadPhotosView()
    func showCamera()
}

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

    private var menuPages: [AddToChatMenuViewController]!
    weak var delegate: AddToChatViewControllerDelegate?
    
    // MARK:- View lifecycle methods.
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        definesPresentationContext = true
        modalPresentationStyle = .overCurrentContext
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mediaCollectionSource = AddToChatMediaCollectionSource(collectionView: mediaCollectionView,
                                                               delegate: self)
        setUpMenuPageViewController()
    }
    
    func setUpMenuPageViewController() {
        let firstPageController = AddToChatMenuViewController(nibName: nil, bundle: nil)
        firstPageController.delegate = self
        let secondPageController = AddToChatMenuViewController(nibName: nil, bundle: nil)
        secondPageController.delegate = self
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
        dismiss(animated: true, completion: nil)
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

extension AddToChatViewController: AddToChatMenuViewControllerDelegate {
    func didTap(itemAtIndex index: Int, viewController: AddToChatMenuViewController) {
        var actualMenuIndex = 0
        if menuPages.first == viewController {
            actualMenuIndex = index
        } else {
            guard let totalMenusInFirstPage = menuPages.first?.menus?.count else {
                return
            }
            
            actualMenuIndex = (totalMenusInFirstPage - 1) + index
        }
        
        switch actualMenuIndex {
        case 0:
            dismiss(animated: true, completion: nil)
            delegate?.loadPhotosView()
        default:
            break
        }
    }
}

extension AddToChatViewController: AddToChatMediaCollectionSourceDelegate {
    func moreButtonTapped() {
        dismiss(animated: true, completion: nil)
        delegate?.loadPhotosView()
    }
    
    func sendAsset(asset: PHAsset) {
        if let delegate = delegate {
            delegate.send(asset: asset)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func showCamera() {
        dismiss(animated: true, completion: nil)
        delegate?.showCamera()
    }
}

