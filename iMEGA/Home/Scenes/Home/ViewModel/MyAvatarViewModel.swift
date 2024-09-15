import Foundation
import MEGADesignToken
import MEGADomain
import MEGAPresentation
import MEGARepo
import MEGASDKRepo

protocol MyAvatarViewModelInputs {

    /// Tells view model that view is ready to display the account
    func viewIsReady()

    func viewIsAppearing()
}

protocol MyAvatarViewModelOutputs {

    /// Stores user's avatar image once loaded.
    var avatarImage: UIImage { get }

    /// Stores number of notifications of current signed in user.
    var notificationNumber: String { get }
}

protocol MyAvatarViewModelType {

    var inputs: any MyAvatarViewModelInputs { get }

    var outputs: any MyAvatarViewModelOutputs { get }

    var notifyUpdate: ((any MyAvatarViewModelOutputs) -> Void)? { get set }
}

final class MyAvatarViewModel: NSObject {

    // MARK: - MyAvatarViewModelType

    var notifyUpdate: ((any MyAvatarViewModelOutputs) -> Void)?

    // MARK: - View States

    var avatarImage: UIImage = UIImage()

    var userAlertCount: Int = 0
    
    var unreadNotificationCount: Int = 0

    var incomingContactRequestCount: Int = 0
    
    var refreshUnreadNotificationCountTask: Task<Void, Never>?

    // MARK: - Dependencies

    private let megaNotificationUseCase: any MEGANotificationUseCaseProtocol
    private let userImageUseCase: any UserImageUseCaseProtocol
    private let megaHandleUseCase: any MEGAHandleUseCaseProtocol
         
    init(
        megaNotificationUseCase: some MEGANotificationUseCaseProtocol,
        userImageUseCase: some UserImageUseCaseProtocol,
        megaHandleUseCase: some MEGAHandleUseCaseProtocol
    ) {
        self.megaNotificationUseCase = megaNotificationUseCase
        self.userImageUseCase = userImageUseCase
        self.megaHandleUseCase = megaHandleUseCase
    }
    
    deinit {
        refreshUnreadNotificationCountTask?.cancel()
        refreshUnreadNotificationCountTask = nil
    }
}

// MARK: - MyAvatarViewModelInputs

extension MyAvatarViewModel: MyAvatarViewModelInputs {

    func viewIsReady() {
        observeUserAlertsAndContactRequests()
        
        refreshUnreadNotificationCount()
    }

    func viewIsAppearing() {
        loadAvatarImage()
        
        refreshUnreadNotificationCount()
    }
}

// MARK: - Load Avatar Image

extension MyAvatarViewModel {
    private func loadAvatarImage() {
        guard let base64Handle = megaHandleUseCase.base64Handle(forUserHandle: MEGAChatSdk.shared.myUserHandle),
              let avatarBackgroundHexColor = userImageUseCase.avatarColorHex(forBase64UserHandle: base64Handle) else {
            MEGALogDebug("Base64 handle not found for handle")
            return
        }
        
        let avatarHandler = UserAvatarHandler(
            userImageUseCase: userImageUseCase,
            initials: MEGAChatSdk.shared.myFullname?.initialForAvatar() ?? "M",
            avatarBackgroundColor: UIColor.colorFromHexString(avatarBackgroundHexColor) ?? TokenColors.Text.primary,
            size: CGSize(width: 28, height: 28)
        )
        
        Task {
            self.avatarImage = await avatarHandler.avatar(for: base64Handle)
            self.notifyUpdate?(self.outputs)
        }
    }
}

// MARK: - Load User Alerts

extension MyAvatarViewModel {

    private func observeUserAlertsAndContactRequests() {
        megaNotificationUseCase.observeUserContactRequests { [weak self] in
            self?.loadUserContactRequest()
        }

        megaNotificationUseCase.observeUserAlerts { [weak self] in
            self?.loadUserAlerts()
        }
    }

    private func loadUserContactRequest() {
        incomingContactRequestCount = megaNotificationUseCase.incomingContactRequest().count
        notifyUpdate?(outputs)
    }

    private func loadUserAlerts() {
        userAlertCount = megaNotificationUseCase.relevantAndNotSeenAlerts()?.count ?? 0
        notifyUpdate?(outputs)
    }
    
    private func refreshUnreadNotificationCount() {
        refreshUnreadNotificationCountTask = Task {
            let newUnreadCount = await megaNotificationUseCase.unreadNotificationIDs().count
            
            guard newUnreadCount != unreadNotificationCount else { return }
            unreadNotificationCount = newUnreadCount
            
            await MainActor.run { notifyUpdate?(outputs) }
        }
    }
}

// MARK: - MyAvatarViewModelType

extension MyAvatarViewModel: MyAvatarViewModelType {

    var inputs: any MyAvatarViewModelInputs { self }

    var outputs: any MyAvatarViewModelOutputs {
        MyAvatarOutputViewModel(
            avatarImage: resizedAvartarImage,
            notificationNumber: notificationNumber
        )
    }

    // MARK: - MyAvatarViewModelOutputs

    private var resizedAvartarImage: UIImage {
        avatarImage.resize(to: CGSize(width: 28, height: 28)).withRoundedCorners()
    }

    private var notificationNumber: String {
        let totalNumber = userAlertCount + incomingContactRequestCount + unreadNotificationCount
        if totalNumber > 99 {
            return "99+"
        }
        return totalNumber > 0 ? "\(totalNumber)" : ""
    }

    struct MyAvatarOutputViewModel: MyAvatarViewModelOutputs {

        var avatarImage: UIImage

        var notificationNumber: String
    }
}

// MARK: - MyAvatarUpdatesObserver
protocol MyAvatarUpdatesObserver {
    var notifyUpdate: ((any MyAvatarViewModelOutputs) -> Void)? { get set }
}

protocol MyAvatarObserver: MyAvatarViewModelInputs & MyAvatarUpdatesObserver {}

extension MyAvatarViewModel: MyAvatarObserver {}

final class MockMyAvatarUpdatesObserver: MyAvatarObserver {
    var notifyUpdate: ((any MyAvatarViewModelOutputs) -> Void)?

    init(notifyUpdate: ((any MyAvatarViewModelOutputs) -> Void)? = nil) {
        self.notifyUpdate = notifyUpdate
    }

    func viewIsReady() {}
    func viewIsAppearing() {}
}
