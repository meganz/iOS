import Foundation

protocol HomeAccountViewModelInputs {

    /// Tells view model that view is ready to display the account
    func viewIsReady()

    func viewIsAppearing()
}

protocol HomeAccountViewModelOutputs {

    /// Stores user's avatar image once loaded.
    var avatarImage: UIImage { get }

    /// Stores number of notifications of current signed in user.
    var notificationNumber: String { get }
}

protocol HomeAccountViewModelType {

    var inputs: HomeAccountViewModelInputs { get }

    var outputs: HomeAccountViewModelOutputs { get }

    var notifyUpdate: ((HomeAccountViewModelOutputs) -> Void)? { get set }
}

final class HomeAccountViewModel {

    // MARK: - HomeAccountViewModelType

    var notifyUpdate: ((HomeAccountViewModelOutputs) -> Void)?

    // MARK: - View States

    var avatarImage: Result<UIImage, Error>? = nil

    var userAlertCount: Int = 0

    var incomingContactRequestCount: Int = 0

    // MARK: - Dependencies

    private let megaNotificationUseCase: MEGANotificationUseCaseProtocol

    private let megaAvatarUseCase: MEGAAvatarUseCaseProtocol

    private let megaAavatarGeneratingUseCase: MEGAAvatarGeneratingUseCaseProtocol

    init(
        megaNotificationUseCase: MEGANotificationUseCaseProtocol,
        megaAvatarUseCase: MEGAAvatarUseCaseProtocol,
        megaAavatarGeneratingUseCase: MEGAAvatarGeneratingUseCaseProtocol
    ) {
        self.megaNotificationUseCase = megaNotificationUseCase
        self.megaAvatarUseCase = megaAvatarUseCase
        self.megaAavatarGeneratingUseCase = megaAavatarGeneratingUseCase
    }
}

// MARK: - HomeAccountViewModelInputs

extension HomeAccountViewModel: HomeAccountViewModelInputs {

    func viewIsReady() {
        observeUserAlertsAndContactRequests()
    }

    func viewIsAppearing() {
        loadAvatarImageIfAvatarIsMissing()
    }
}

// MARK: - Load Avatar Image

extension HomeAccountViewModel {

    private func loadAvatarImageIfAvatarIsMissing() {
        guard avatarImage != nil else {
            loadAvatarImage()
            return
        }

        guard case .success = avatarImage else {
            loadAvatarImage()
            return
        }
    }

    private func loadAvatarImage() {
        if let cachedAvatarImage = megaAvatarUseCase.getCachedAvatarImage() {
            self.avatarImage = .success(cachedAvatarImage)
            self.notifyUpdate?(self.outputs)
            return
        }

        if let generatedAvatarImage = generatedAvatarImage(withAvatarSize: CGSize(width: 28, height: 28)) {
            self.avatarImage = .success(generatedAvatarImage)
            self.notifyUpdate?(self.outputs)
        }

        megaAvatarUseCase.loadRemoteAvatarImage { [weak self] image in
            guard let self = self, let image = image else { return }
            self.avatarImage = .success(image)
            self.notifyUpdate?(self.outputs)
        }
    }

    private func generatedAvatarImage(withAvatarSize avatarSize: CGSize) -> UIImage? {
        guard let avatarName = megaAavatarGeneratingUseCase.avatarName(),
              let avatarBackgroundColorHex = megaAavatarGeneratingUseCase.avatarBackgroundColorHex(),
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

extension HomeAccountViewModel {

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

// MARK: - HomeAccountViewModelType

extension HomeAccountViewModel: HomeAccountViewModelType {

    var inputs: HomeAccountViewModelInputs { self }

    var outputs: HomeAccountViewModelOutputs {
        HomeAccountOutputViewModel(
            avatarImage: resizedAvartarImage,
            notificationNumber: notificationNumber
        )
    }

    // MARK: - HomeAccountViewModelOutputs

    private var resizedAvartarImage: UIImage {
        switch avatarImage {
        case .success(let avatarImage):
            return avatarImage.resize(to: CGSize(width: 28, height: 28)).withRoundedCorners()
        case .failure, .none:
            return generatedAvatarPlaceholder().withRoundedCorners()
        }
    }

    private var notificationNumber: String {
        userAlertCount + incomingContactRequestCount > 0 ? "\(userAlertCount + incomingContactRequestCount)" : ""
    }

    struct HomeAccountOutputViewModel: HomeAccountViewModelOutputs {

        var avatarImage: UIImage

        var notificationNumber: String
    }
}
