import Combine
import MEGADomain
import MEGAL10n
import MEGAPresentation

@objc final class ContactsViewModel: NSObject {
    private let sdk: MEGASdk
    private let contactsMode: ContactsMode
    private let shareUseCase: any ShareUseCaseProtocol
    private let isHiddenNodesEnabled: Bool
    
    private var callLimitsSubscription: AnyCancellable?
    private var loadingTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    let dismissViewSubject = PassthroughSubject<Void, Never>()
    @Published private(set) var isLoading = false
    @Published private(set) var alertModel: AlertModel?
    
    var bannerConfig: BannerView.Config?
    var bannerReloadTrigger: (() -> Void)?
    var bannerDecider: (Int) -> Bool = { _ in false }
    var callLimitations: CallLimitations? {
        didSet {
            callLimitsSubscription?.cancel()
            callLimitsSubscription = nil
            
            callLimitsSubscription = callLimitations?
                .limitsChangedPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    MEGALogDebug("[CallLimitations] ContactsViewModel reloadWarning triggered")
                    self?.reloadWarningBanner()
                }
        }
    }
    var dismissedBannerWarning = false
    var shouldShowBannerWarning: Bool {
        bannerConfig != nil && !dismissedBannerWarning
    }
    
    init(
        sdk: MEGASdk,
        contactsMode: ContactsMode,
        shareUseCase: some ShareUseCaseProtocol,
        featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider
    ) {
        self.sdk = sdk
        self.contactsMode = contactsMode
        self.shareUseCase = shareUseCase
        isHiddenNodesEnabled = featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes)
    }
    
    deinit {
        loadingTask?.cancel()
    }
    
    func shouldShowBannerWarning(
        selectedUsersCount: Int
    ) -> Bool {
        reachedLimitOfCallParticipants(selectedUsersCount: selectedUsersCount)
        && !dismissedBannerWarning
    }
    
    func reloadWarningBanner() {
        assert(bannerReloadTrigger != nil)
        bannerReloadTrigger?()
    }
    
    private func reachedLimitOfCallParticipants(
        selectedUsersCount: Int
    ) -> Bool {
        bannerDecider(selectedUsersCount)
    }
   
    @objc
    func shouldShowUnverifiedContactsBanner(
        contactsMode: ContactsMode,
        selectedUsersArray: NSMutableArray?,
        visibleUsersArray: NSMutableArray?
    ) -> Bool {
        
        guard sdk.isContactVerificationWarningEnabled,
              [ContactsMode.shareFoldersWith, ContactsMode.folderSharedWith].contains(contactsMode) else {
            return false
        }

        var users: [MEGAUser]?

        // We are displaying the warning banner in this screen when it is started for two contact modes:
        // 1. ContactsMode == .shareFoldersWith (when we are starting "Share Folder" flow)
        // 2. ContactsMode == .folderShared with (when the folder is already shared and we tapped on "Manage Share")
        if contactsMode == .shareFoldersWith {
            // In the first point of entry, users which we want to share folder with are stored in selectedUsersArray.
            // We have couple of options to add user to share a folder with:
            // 1. Select them from the list of our MEGA contacts
            // 2. Add external users via contacts, email, or QR code
            // Because of that, our selectedUsersArray can be consisted of both MEGAUser and String objects which represent emails and all three options
            // and look something like this ["mega@test.com", MEGAUser, "mega@test2.com"]
            users = selectedUsersArray?.filter { $0 is MEGAUser } as? [MEGAUser]
        } else {
            // In the second point, users with which the folder is already shared are stored in stored in visibleUsersArray.
            users = visibleUsersArray as? [MEGAUser]
        }

        // We check if in the existing MEGA users we have some which are unverified
        let hasExistingUnverifiedContacts = users?.contains(where: { !sdk.areCredentialsVerified(of: $0) }) == true

        // We check if we have invited non existing MEGA users by contacts, email, or QR
        // In that situation, we consider these users as unverified also, and we should display the banner
        let selectedUsersCount = selectedUsersArray?.count ?? 0
        let hasInvitedNonExistingUsers = selectedUsersArray != nil && selectedUsersCount > 0 &&
        (users?.count ?? 0) < selectedUsersCount

        return hasExistingUnverifiedContacts || hasInvitedNonExistingUsers
    }
    
    @objc func showAlertForSensitiveDescendants(_ nodes: [MEGANode]) {
        guard isHiddenNodesEnabled,
              contactsMode == .shareFoldersWith else { return }
        isLoading = true
        defer { isLoading = false }
        
        loadingTask = Task { @MainActor in
            do {
                guard try await shareUseCase.doesContainSensitiveDescendants(in: nodes.toNodeEntities()) else { return }
                
                alertModel = AlertModel.makeShareContainsSensitiveItems(nodeCount: nodes.count) { @MainActor [weak self] in
                    self?.dismissViewSubject.send()
                }
            } catch {
                MEGALogError("[\(type(of: self))]: determineIfAlbumsContainSensitiveNodes returned \(error.localizedDescription)")
            }
        }
    }
}

private extension AlertModel {
    static func makeShareContainsSensitiveItems(nodeCount: Int, cancelHandler: @escaping () -> Void) -> Self {
        let message = if nodeCount > 1 {
            Strings.Localizable.ShareFolder.Sensitive.Alert.Message.multi
        } else {
            Strings.Localizable.ShareFolder.Sensitive.Alert.Message.single
        }
        return .init(
            title: Strings.Localizable.ShareFolder.Sensitive.Alert.title,
            message: message,
            actions: [
                .init(title: Strings.Localizable.cancel, style: .cancel,
                      handler: cancelHandler),
                .init(title: Strings.Localizable.continue, style: .default,
                      isPreferredAction: true, handler: {})
            ])
    }
}
