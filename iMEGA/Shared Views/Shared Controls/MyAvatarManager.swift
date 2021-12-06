
@objc protocol MyAvatarManagerProtocol {
    var myAvatarBarButton: UIBarButtonItem? { get }
    func setup()
    func refreshMyAvatar()
}

@objc protocol MyAvatarPresenterProtocol: AnyObject {
    func configureMyAvatarManager()
    func refreshMyAvatar()
    func setupMyAvatar(barButton: UIBarButtonItem)
}

@objc final class MyAvatarManager: NSObject, MyAvatarManagerProtocol {
    var myAvatarViewModel: MyAvatarViewModelType?
    let navigationController: UINavigationController
    var badgeButton: BadgeButton?
    var myAvatarBarButton: UIBarButtonItem? {
        guard let badgeButton = badgeButton else { return nil}
        return UIBarButtonItem(customView: badgeButton)
    }
    weak var delegate: MyAvatarPresenterProtocol?
    
    init(navigationController: UINavigationController, delegate: MyAvatarPresenterProtocol) {
        self.navigationController = navigationController
        self.delegate = delegate
    }
    
    func setup() {
        myAvatarViewModel = MyAvatarViewModel(
            megaNotificationUseCase: MEGANotificationUseCase(
                userAlertsClient: .live
            ),
            megaAvatarUseCase: MEGAavatarUseCase(
                megaAvatarClient: .live,
                avatarFileSystemClient: .live,
                megaUserClient: .live,
                fileRepo: FileSystemRepository(fileManager: FileManager.default)
            ),
            megaAvatarGeneratingUseCase: MEGAAavatarGeneratingUseCase(
                storeUserClient: .live,
                megaAvatarClient: .live,
                megaUserClient: .live
            )
        )
        
        setupBarButtonItems()
        setupMyAvatarEventListener()
    }
    
    @objc private func navigateToMyAccount() {
        let myAccountViewController = UIStoryboard(name: "MyAccount", bundle: nil)
            .instantiateViewController(withIdentifier: "MyAccountHall")
        navigationController.pushViewController(myAccountViewController, animated: true)
    }
    
    func setupBarButtonItems() {
        let badgeButton = BadgeButton()
        self.badgeButton = badgeButton
        badgeButton.addTarget(self, action: #selector(navigateToMyAccount), for: .touchUpInside)
        
        delegate?.setupMyAvatar(barButton: UIBarButtonItem(customView: badgeButton))
    }
    
    func setupMyAvatarEventListener() {
        myAvatarViewModel?.notifyUpdate = { [weak self] output in
            guard let self = self else { return }
            let resizedImage = output.avatarImage

            asyncOnMain {
                if let badgeButton = self.badgeButton {
                    badgeButton.setBadgeText(output.notificationNumber)
                    badgeButton.setImage(resizedImage, for: .normal)
                }
            }
        }
        myAvatarViewModel?.inputs.viewIsReady()
    }
    
    func refreshMyAvatar() {
        myAvatarViewModel?.inputs.viewIsAppearing()
    }
}
