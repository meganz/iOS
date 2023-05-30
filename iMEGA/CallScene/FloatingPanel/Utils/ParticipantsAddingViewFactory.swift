import MEGADomain

struct ParticipantsAddingViewFactory {
    let accountUseCase: AccountUseCaseProtocol
    let chatRoomUseCase: ChatRoomUseCaseProtocol
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
    
    func addContactsViewController(
        withContactsMode contactsMode: ContactsMode,
        additionallyExcludedParticipantsId: Set<HandleEntity>?,
        selectedUsersHandler: @escaping (([HandleEntity]) -> Void)
    ) -> UINavigationController? {
        let storyboard = UIStoryboard(name: "Contacts", bundle: nil)
        guard let navigationController = storyboard.instantiateViewController(
            withIdentifier: "ContactsNavigationControllerID"
        ) as? UINavigationController,
              let contactController = navigationController.viewControllers.first as? ContactsViewController else {
            return nil
        }
        
        contactController.contactsMode = contactsMode
        
        let chatRoomCurrentParticipants = chatRoom
            .peers
            .compactMap { $0.privilege.isPeerVisibleByPrivilege() ? $0.handle : nil }
        
        let excludedParticipantsId = (additionallyExcludedParticipantsId ?? []).union(chatRoomCurrentParticipants)
        
        let participantsDict = excludedParticipantsId.reduce(into: [NSNumber: NSNumber]()) {
            $0[NSNumber(value: $1)] = NSNumber(value: $1)
        }
        contactController.participantsMutableDictionary = NSMutableDictionary(dictionary: participantsDict)
        contactController.userSelected = { selectedUsers in
            guard let users = selectedUsers else { return }
            selectedUsersHandler(users.map(\.handle))
        }
    
        return navigationController
    }
    
    // MARK: - Private methods
    private func alert(withTitle title: String, message: String, inviteAction: @escaping () -> Void) -> UIAlertController {
        let inviteButtonTitle = Strings.Localizable.Meetings.AddContacts.AllContactsAdded.confirmationButtonTitle
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel, handler:nil))
        let inviteAction = UIAlertAction(title: inviteButtonTitle, style: .default) { _ in
            inviteAction()
        }
        alertController.addAction(inviteAction)
        alertController.preferredAction = inviteAction
        return alertController
    }
}
