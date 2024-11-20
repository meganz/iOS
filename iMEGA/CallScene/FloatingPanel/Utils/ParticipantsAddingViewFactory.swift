import Chat
import MEGADomain
import MEGAL10n
import MEGAPresentation

struct ParticipantsAddingViewFactory {
    let accountUseCase: any AccountUseCaseProtocol
    let chatRoomUseCase: any ChatRoomUseCaseProtocol
    let chatRoom: ChatRoomEntity
    
    var hasVisibleContacts: Bool {
        accountUseCase.contacts().contains { $0.visibility == .visible }
    }
    
    func hasNonAddedVisibleContacts(withExcludedHandles handles: Set<HandleEntity>) -> Bool {
        let peerHandles = chatRoomUseCase.peerHandles(forChatRoom: chatRoom)
        let excludedHandles = handles.union(peerHandles)

        let hasNonAddedVisibleContacts = accountUseCase.contacts()
            .contains { user in
                user.visibility == .visible
                && excludedHandles.notContains(where: { user.handle == $0})
            }
        
        guard hasNonAddedVisibleContacts else {
            return false
        }
        
        return true
    }
    
    func allContactsAlreadyAddedAlert(inviteAction: @escaping () -> Void) -> UIAlertController {
        let title = Strings.Localizable.Meetings.AddContacts.AllContactsAdded.title
        let message = Strings.Localizable.Meetings.AddContacts.AllContactsAdded.description
        return alert(withTitle: title, message: message, inviteAction: inviteAction)
    }
    
    func noAvailableContactsAlert(inviteAction: @escaping () -> Void) -> UIAlertController {
        let title = Strings.Localizable.Meetings.AddContacts.ZeroContactsAvailable.title
        let message = Strings.Localizable.Meetings.AddContacts.ZeroContactsAvailable.description
        return alert(withTitle: title, message: message, inviteAction: inviteAction)
    }
    
    func inviteContactController() -> InviteContactViewController? {
        let storyboard = UIStoryboard(name: "InviteContact", bundle: nil)
        guard let inviteContactsViewController = storyboard.instantiateViewController(identifier: "InviteContactViewControllerID") as? InviteContactViewController else {
            return nil
        }
        
        return inviteContactsViewController
    }
    
    // small trampoline method to not be force to start using config parameter in the existing call sites
    func addContactsViewController(
        withContactsMode contactsMode: ContactsMode,
        additionallyExcludedParticipantsId: Set<HandleEntity>?,
        selectedUsersHandler: @escaping (([HandleEntity]) -> Void)
    ) -> UINavigationController? {
        addContactsViewController(
            contactPickerConfig: .init(
                mode: contactsMode,
                excludedParticipantIds: additionallyExcludedParticipantsId
            ),
            selectedUsersHandler: selectedUsersHandler
        )
    }
    
    func addContactsViewController(
        contactPickerConfig: ContactPickerConfig,
        selectedUsersHandler: @escaping (([HandleEntity]) -> Void)
    ) -> UINavigationController? {
        let storyboard = UIStoryboard(name: "Contacts", bundle: nil)
        guard let navigationController = storyboard.instantiateViewController(
            withIdentifier: "ContactsNavigationControllerID"
        ) as? UINavigationController,
              let contactController = navigationController.viewControllers.first as? ContactsViewController else {
            return nil
        }
        
        contactController.contactsMode = contactPickerConfig.mode
        
        let chatRoomCurrentParticipants = chatRoom
            .peers
            .compactMap { $0.privilege.isPeerVisibleByPrivilege() ? $0.handle : nil }
        
        let excludedParticipantsId = (contactPickerConfig.excludedParticipantIds ?? []).union(chatRoomCurrentParticipants)
        
        let participantsDict = excludedParticipantsId.reduce(into: [NSNumber: NSNumber]()) {
            $0[NSNumber(value: $1)] = NSNumber(value: $1)
        }
        contactController.participantsMutableDictionary = NSMutableDictionary(dictionary: participantsDict)
        
        let accountDetails = accountUseCase.currentAccountDetails
        let presentUpgrade: () -> Void = {
            guard let accountDetails else { return }
            UpgradeAccountPlanRouter(
                presenter: contactController,
                accountDetails: accountDetails
            ).start()
        }
        
        // [MEET-3401] conditionally show banner about limit of participants for a meeting
        // organized by the free-tier user
        // for a organiser, we it will be possible to show upgrade modal sheet from it
        // for a host-non-organiser, it can be dismissed (once per lifetime of the view controller)
        let bannerConfig = bannerConfigFactory(
            warningMode: contactPickerConfig.canInviteParticipants ? .dismissible : .noWarning,
            presentUpgrade: presentUpgrade
        )
        if let bannerConfig {
            contactController.setBannerConfig(bannerConfig)
            contactController.viewModel.bannerDecider = contactPickerConfig.participantLimitAchieved
            contactController.viewModel.callLimitations = contactPickerConfig.callLimitations
            contactController.viewModel.bannerReloadTrigger = { [weak contactController] in
                contactController?.handleContactsNotVerifiedHeaderVisibility()
            }
        }
        contactController.userSelected = { selectedUsers in
            guard let users = selectedUsers else { return }
            selectedUsersHandler(users.map(\.handle))
        }
    
        return navigationController
    }
    
    private func bannerConfigFactory(
        warningMode: ParticipantLimitWarningMode,
        presentUpgrade: @escaping () -> Void
    ) -> BannerView.Config? {
        switch warningMode {
        case .dismissible:
            return .init(
                copy: Strings.Localizable.Meetings.Warning.overParticipantLimit,
                theme: .dark,
                closeAction: {} // close action handled inside ContactsViewController
            )
        case .noWarning:
            return nil
        }
    }
    
    // MARK: - Private methods
    private func alert(withTitle title: String, message: String, inviteAction: @escaping () -> Void) -> UIAlertController {
        let inviteButtonTitle = Strings.Localizable.Meetings.AddContacts.AllContactsAdded.confirmationButtonTitle
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel, handler: nil))
        let inviteAction = UIAlertAction(title: inviteButtonTitle, style: .default) { _ in
            inviteAction()
        }
        alertController.addAction(inviteAction)
        alertController.preferredAction = inviteAction
        return alertController
    }
}

struct ContactPickerConfig {
    var mode: ContactsMode
    var excludedParticipantIds: Set<HandleEntity>?
    var canInviteParticipants: Bool = false
    // this is needed to that we can subscribe to the `limitsChangedPublisher`
    // to get dynamic reload of the warning limit banner
    var callLimitations: CallLimitations?
    // this will check if after selectionCount the limit of free call participants will be equalised or exceeded
    var participantLimitAchieved: (_ selectionCount: Int) -> Bool = { _ in false }
}
