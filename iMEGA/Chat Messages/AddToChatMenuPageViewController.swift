import MEGAPermissions
import UIKit

protocol AddToChatMenuPageViewControllerDelegate: AnyObject {
    func loadPhotosView()
    func showCloudDrive()
    func showVoiceClip()
    func showContacts()
    func showScanDoc()
    func showLocation()
    func showGiphy()
    func showFilesApp()
    func numberOfPages(_ pages: Int)
    func currentSelectedPageIndex(_ pageIndex: Int)
}

class AddToChatMenuPageViewController: UIPageViewController {
    
    weak var menuDelegate: (any AddToChatMenuPageViewControllerDelegate)?
    
    private var menuPages = [AddToChatMenuViewController]()
    
    private var numberOfMenuPerPages: Int {
        return menuPerRow * numberOfRowsForMenu
    }
    
    private let permissionHandler: some DevicePermissionsHandling = DevicePermissionsHandler.makeHandler()
    
    private var numberOfRowsForMenu = 2
    private var menuPerRow = 4
    private var currentPage = 0
    
    private lazy var menus = AddToChatMenu.menus()
    
    private var numberOfPagesRequired: Int {
        guard let menus = menus else {
            return 0
        }
        
        return Int(ceil(Double(menus.count) / Double(numberOfMenuPerPages)))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        populateMenuPages()
        
        if let firsPage = menuPages.first {
            setViewControllers([firsPage],
                               direction: .forward,
                               animated: false,
                               completion: nil)
        }
        
        dataSource = self
        delegate = self
    }
    
    private func populateMenuPages() {
        guard let menus = menus else {
            return
        }
        
        menuPages = (0..<numberOfPagesRequired).map { pageIndex in
            let menuViewController = AddToChatMenuViewController()
            menuViewController.delegate = self
            
            let firstItemIndex = (self.numberOfMenuPerPages * pageIndex)
            let possibleLastIndex = (firstItemIndex + self.numberOfMenuPerPages - 1)
            let lastItemIndex = possibleLastIndex < menus.count ? possibleLastIndex : menus.count - 1
            let menuList = (firstItemIndex...lastItemIndex).map { menus[$0] }
            
            menuViewController.menus = menuList
            
            return menuViewController
        }
        
        menuDelegate?.numberOfPages(menuPages.count)
    }
    
    func moveToPageAtIndex(_ pageIndex: Int) {
        guard pageIndex < menuPages.count, currentPage != pageIndex else { return }
        
        let direction: UIPageViewController.NavigationDirection = currentPage < pageIndex ? .forward : .reverse
        currentPage = pageIndex
        setViewControllers([menuPages[pageIndex]],
                           direction: direction,
                           animated: true,
                           completion: nil)
        
    }
    
    func totalRequiredHeight(forWidth width: CGFloat,
                             horizontalPaddding: CGFloat) -> CGFloat {
        let eachMenuWidth = ceil((width - horizontalPaddding) / CGFloat(menuPerRow))
        let rowSpacing = AddToChatMenuViewController().rowSpacing
        return (eachMenuWidth * CGFloat(numberOfRowsForMenu)) + rowSpacing
    }
    
    func totalRequiredWidth(forAvailableHeight height: CGFloat,
                            horizontalPaddding: CGFloat) -> CGFloat {
        let rowSpacing = AddToChatMenuViewController().rowSpacing
        let eachMenuWidth = (height - rowSpacing) / CGFloat(numberOfRowsForMenu)
        return eachMenuWidth * CGFloat(menuPerRow) 
    }
}

extension AddToChatMenuPageViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let menuViewController = viewController as? AddToChatMenuViewController,
              let index = menuPages.firstIndex(of: menuViewController),
              index > 0,
              menuPages.isNotEmpty else {
            return nil
        }
        
        return menuPages[index - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let menuViewController = viewController as? AddToChatMenuViewController,
              let index = menuPages.firstIndex(of: menuViewController),
              (index + 1) < menuPages.count else {
            return nil
        }
        
        return menuPages[index + 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        if completed {
            if let currentViewController = pageViewController.viewControllers?.first as? AddToChatMenuViewController,
               let index = menuPages.firstIndex(of: currentViewController) {
                currentPage = index
                menuDelegate?.currentSelectedPageIndex(index)
            }
        }
    }
}

extension AddToChatMenuPageViewController: AddToChatMenuViewControllerDelegate {
    func didTap(menu: AddToChatMenu) {
        guard let menuNameKey = menu.menuNameKey else {
            MEGALogDebug("Menu name key is nil for didTap")
            return
        }
        
        switch menuNameKey {
        case .photos:
            permissionHandler.photosPermissionWithCompletionHandler {[weak self] granted in
                guard let self else { return }
                if granted {
                    menuDelegate?.loadPhotosView()
                } else {
                    PermissionAlertRouter
                        .makeRouter(deviceHandler: permissionHandler)
                        .alertPhotosPermission()
                }
            }
        case .file:
            menuDelegate?.showCloudDrive()
        case .contact:
            menuDelegate?.showContacts()
        case .scanDoc:
            menuDelegate?.showScanDoc()
        case .location:
            menuDelegate?.showLocation()
        case .voiceClip:
            menuDelegate?.showVoiceClip()
        case .giphy:
            menuDelegate?.showGiphy()
        case .filesApp:
            menuDelegate?.showFilesApp()
        }
    }
}
