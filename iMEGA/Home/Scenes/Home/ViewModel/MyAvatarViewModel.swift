import Foundation

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

    var inputs: MyAvatarViewModelInputs { get }

    var outputs: MyAvatarViewModelOutputs { get }

    var notifyUpdate: ((MyAvatarViewModelOutputs) -> Void)? { get set }
}

final class MyAvatarViewModel: NSObject {

    // MARK: - MyAvatarViewModelType

    var notifyUpdate: ((MyAvatarViewModelOutputs) -> Void)?

    // MARK: - View States

    var avatarImage: Result<UIImage, Error>?

    var userAlertCount: Int = 0

    var incomingContactRequestCount: Int = 0

    // MARK: - Dependencies

    private let megaNotificationUseCase: MEGANotificationUseCaseProtocol

    private let megaAvatarUseCase: MEGAAvatarUseCaseProtocol

    private let megaAvatarGeneratingUseCase: MEGAAvatarGeneratingUseCaseProtocol

    init(
        megaNotificationUseCase: MEGANotificationUseCaseProtocol,
        megaAvatarUseCase: MEGAAvatarUseCaseProtocol,
        megaAvatarGeneratingUseCase: MEGAAvatarGeneratingUseCaseProtocol
    ) {
        self.megaNotificationUseCase = megaNotificationUseCase
        self.megaAvatarUseCase = megaAvatarUseCase
        self.megaAvatarGeneratingUseCase = megaAvatarGeneratingUseCase
    }
}

// MARK: - MyAvatarViewModelInputs

extension MyAvatarViewModel: MyAvatarViewModelInputs {

    func viewIsReady() {
        observeUserAlertsAndContactRequests()
        
        refreshAvatarWhenCached()
    }

    func viewIsAppearing() {
        loadAvatarImage()
    }
}

// MARK: - Load Avatar Image

extension MyAvatarViewModel {
    private func refreshAvatarWhenCached() {
        guard cachedAvatarImage() != nil else { return }
        loadRemoteAvatarImage()
    }

    
    private func cachedAvatarImage() -> UIImage? {
        return megaAvatarUseCase.getCachedAvatarImage()
    }


    private func loadAvatarImage() {
        if let cachedAvatarImage = cachedAvatarImage() {
            self.avatarImage = .success(cachedAvatarImage)
            self.notifyUpdate?(self.outputs)
            return
        }

        if let generatedAvatarImage = generatedAvatarImage(withAvatarSize: CGSize(width: 28, height: 28)) {
            self.avatarImage = .success(generatedAvatarImage)
            self.notifyUpdate?(self.outputs)
        }
        
        loadRemoteAvatarImage()
    }
    
    
    private func loadRemoteAvatarImage() {
        megaAvatarUseCase.loadRemoteAvatarImage { [weak self] image in
            guard let self = self, let image = image else { return }
            self.avatarImage = .success(image)
            self.notifyUpdate?(self.outputs)
        }
    }

    private func generatedAvatarImage(withAvatarSize avatarSize: CGSize) -> UIImage? {
        guard let avatarName = megaAvatarGeneratingUseCase.avatarName(),
              let avatarBackgroundColorHex = megaAvatarGeneratingUseCase.avatarBackgroundColorHex(),
              !avatarName.isEmpty
        else {
            return nil
        }
        let avatarBackgroundColor = UIColor.mnz_(fromHexString: avatarBackgroundColorHex)
        return UIImage(
            forName: avatarName,
            size: avatarSize,
            backgroundColor: avatarBackgroundColor,
            textColor: .white,
            font: UIFont.systemFont(ofSize: avatarSize.width / 2)
        )
    }

    private func generatedAvatarPlaceholder() -> UIImage {
        let avatarSize = CGSize(width: 28, height: 28)
        return UIImage(
            forName: "M",
            size: avatarSize,
            backgroundColor: UIColor.systemGray,
            textColor: .white,
            font: UIFont.systemFont(ofSize: avatarSize.width / 2)
        )
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
}

// MARK: - MyAvatarViewModelType

extension MyAvatarViewModel: MyAvatarViewModelType {

    var inputs: MyAvatarViewModelInputs { self }

    var outputs: MyAvatarViewModelOutputs {
        MyAvatarOutputViewModel(
            avatarImage: resizedAvartarImage,
            notificationNumber: notificationNumber
        )
    }

    // MARK: - MyAvatarViewModelOutputs

    private var resizedAvartarImage: UIImage {
        switch avatarImage {
        case .success(let avatarImage):
            return avatarImage.resize(to: CGSize(width: 28, height: 28)).withRoundedCorners()
        case .failure, .none:
            return generatedAvatarPlaceholder().withRoundedCorners()
        }
    }

    private var notificationNumber: String {
        let totalNumber = userAlertCount + incomingContactRequestCount
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
