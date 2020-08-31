

import UIKit

protocol AddToChatMenuPageViewControllerDelegate: AnyObject {
    func loadPhotosView()
    func showCloudDrive()
    func startVoiceCall()
    func startVideoCall()
    func showVoiceClip()
    func showContacts()
    func startGroupChat()
    func showLocation()
    func shouldDisableAudioMenu() -> Bool
    func shouldDisableVideoMenu() -> Bool
}

class AddToChatMenuPageViewController: UIPageViewController {
    
    weak var menuDelegate: AddToChatMenuPageViewControllerDelegate?
    
    private var menuPages = [AddToChatMenuViewController]()

    private var numberOfMenuPerPages: Int {
        return menuPerRow * numberOfRowsForMenu
    }

    private var numberOfRowsForMenu = 2
    private var menuPerRow = 4
    
    private lazy var menus = {
        return AddToChatMenu.menus()
    }()
    
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
        
        menuPages = (0..<numberOfPagesRequired).map { [weak self] pageIndex in
            let menuViewController = AddToChatMenuViewController()
            menuViewController.delegate = self
            
            let firstItemIndex = (numberOfMenuPerPages * pageIndex)
            let possibleLastIndex = (firstItemIndex + numberOfMenuPerPages - 1)
            let lastItemIndex = possibleLastIndex < menus.count ? possibleLastIndex : menus.count - 1
            let menuList = (firstItemIndex...lastItemIndex).map { menus[$0] }
            
            menuViewController.menus = menuList
            
            return menuViewController
        }
    }
    
    func updateAudioVideoMenu() {
        menuPages.forEach { menuViewController in
            menuViewController.updateMenus()
        }
    }
    
    func totalRequiredHeight(forWidth width: CGFloat,
                             horizontalPaddding: CGFloat) -> CGFloat {
        let eachMenuWidth = ceil((width - horizontalPaddding) / CGFloat(menuPerRow))
        let rowSpacing = AddToChatMenuViewController().rowSpacing
        return (eachMenuWidth * CGFloat(numberOfRowsForMenu)) + rowSpacing
    }
}

extension AddToChatMenuPageViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let menuViewController = viewController as? AddToChatMenuViewController,
            let index = menuPages.firstIndex(of: menuViewController),
            index > 0,
            menuPages.count > 0 else {
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
}

extension AddToChatMenuPageViewController: AddToChatMenuViewControllerDelegate {
    func didTap(menu: AddToChatMenu) {
        guard let menuNameKey = menu.menuNameKey else {
            MEGALogDebug("Menu name key is nil for didTap")
            return
        }
        
        switch menuNameKey {
        case .photos:
            DevicePermissionsHelper.photosPermission { granted in
                if granted {
                    self.menuDelegate?.loadPhotosView()
                } else {
                    DevicePermissionsHelper.alertPhotosPermission()
                }
            }
        case .file:
            menuDelegate?.showCloudDrive()
        case .voice:
            menuDelegate?.startVoiceCall()
        case .video:
            menuDelegate?.startVideoCall()
        case .contact:
            menuDelegate?.showContacts()
        case .startGroup:
            menuDelegate?.startGroupChat()
        case .location:
            menuDelegate?.showLocation()
        case .voiceClip:
            menuDelegate?.showVoiceClip()
        }
    }
    
    func shouldDisable(menu: AddToChatMenu) -> Bool {
        guard let menuNameKey = menu.menuNameKey else {
            MEGALogDebug("Menu name key is nil for shouldDisable")
            return false
        }
        
        switch menuNameKey {
        case .voice:
            return menuDelegate?.shouldDisableAudioMenu() ?? false
        case .video:
            return menuDelegate?.shouldDisableVideoMenu() ?? false
        default:
            return false
        }
    }
}

