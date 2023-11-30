import MEGADomain
import MEGASDKRepo

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
    var myAvatarViewModel: (any MyAvatarViewModelType)?
    weak var navigationController: UINavigationController?
    var badgeButton: BadgeButton?
    var myAvatarBarButton: UIBarButtonItem? {
        guard let badgeButton = badgeButton else { return nil}
        return UIBarButtonItem(customView: badgeButton)
    }
    weak var delegate: (any MyAvatarPresenterProtocol)?
    
    init(navigationController: UINavigationController, delegate: some MyAvatarPresenterProtocol) {
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
                accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
                thumbnailRepo: ThumbnailRepository.newRepo,
                handleUseCase: MEGAHandleUseCase(repo: MEGAHandleRepository.newRepo)
            ),
            megaAvatarGeneratingUseCase: MEGAAavatarGeneratingUseCase(
                storeUserClient: .live,
                megaAvatarClient: .live,
                accountUseCase: AccountUseCase(repository: AccountRepository.newRepo)
            )
        )
        
        setupBarButtonItems()
        setupMyAvatarEventListener()
    }
    
    @objc private func navigateToMyAccount() {
        guard let navigationController else { return }
        
        MyAccountHallRouter(
            myAccountHallUseCase: MyAccountHallUseCase(repository: AccountRepository.newRepo),
            purchaseUseCase: AccountPlanPurchaseUseCase(repository: AccountPlanPurchaseRepository.newRepo),
            navigationController: navigationController
        ).start()
    }
    
    func setupBarButtonItems() {
        let badgeButton = BadgeButton()
        self.badgeButton = badgeButton
        badgeButton.addTarget(self, action: #selector(navigateToMyAccount), for: .touchUpInside)
        
        delegate?.setupMyAvatar(barButton: UIBarButtonItem(customView: badgeButton))
    }
    
    func setupMyAvatarEventListener() {
        myAvatarViewModel?.notifyUpdate = { [weak self] output in
            guard let self else { return }
            let resizedImage = output.avatarImage

            asyncOnMain {
                if let badgeButton = self.badgeButton {
                    badgeButton.setBadgeText(output.notificationNumber)
                    badgeButton.setAvatarImage(resizedImage)
                }
            }
        }
        myAvatarViewModel?.inputs.viewIsReady()
    }
    
    func refreshMyAvatar() {
        myAvatarViewModel?.inputs.viewIsAppearing()
    }
}
