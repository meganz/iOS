

import UIKit

protocol AddToChatMenuPageViewControllerDelegate: class {
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
    
    private var menuPages: [AddToChatMenuViewController]!

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
        
        menuPages = (0..<numberOfPagesRequired).compactMap { [weak self] pageIndex in
            guard let menus = menus else {
                return nil
            }
            
            let menuViewController = AddToChatMenuViewController(nibName: nil, bundle: nil)
            menuViewController.delegate = self
            
            let firstItemIndex = (numberOfMenuPerPages * pageIndex)
            let possibleLastIndex = (firstItemIndex + numberOfMenuPerPages - 1)
            let lastItemIndex = possibleLastIndex < menus.count ? possibleLastIndex : menus.count - 1
            let menuList = (firstItemIndex...lastItemIndex).map { menus[$0] }
            
            menuViewController.menus = menuList
            
            return menuViewController
        }
        
        setViewControllers([menuPages.first!],
                           direction: .forward,
                           animated: false,
                           completion: nil)
        
        dataSource = self
        delegate = self
    }
    
    func updateAudioVideoMenu() {
        guard let menuPages = menuPages else {
            return
        }
        
        menuPages.forEach { menuViewController in
            menuViewController.updateMenus()
        }
    }
    
    func totalRequiredHeight(forWidth width: CGFloat,
                             horizontalPaddding: CGFloat) -> CGFloat {
        let eachMenuWidth = ceil((width - horizontalPaddding) / CGFloat(menuPerRow))
        let rowSpacing = AddToChatMenuViewController(nibName: nil, bundle: nil).rowSpacing
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
        switch menu.nameKey {
        case "Photos":
            DevicePermissionsHelper.photosPermission { granted in
                if granted {
                    self.menuDelegate?.loadPhotosView()
                } else {
                    DevicePermissionsHelper.alertPhotosPermission()
                }
            }
        case "File":
            menuDelegate?.showCloudDrive()
        case "Voice":
            menuDelegate?.startVoiceCall()
        case "Video":
            menuDelegate?.startVideoCall()
        case "Contact":
            menuDelegate?.showContacts()
        case "Start Group":
            menuDelegate?.startGroupChat()
        case "Location":
            menuDelegate?.showLocation()
        case "Voice Clip":
            menuDelegate?.showVoiceClip()
        default:
            break
        }
    }
    
    func shouldDisable(menu: AddToChatMenu) -> Bool {
        switch menu.nameKey {
        case "Voice":
            return menuDelegate?.shouldDisableAudioMenu() ?? false
        case "Video":
            return menuDelegate?.shouldDisableVideoMenu() ?? false
        default:
            return false
        }
    }
}
