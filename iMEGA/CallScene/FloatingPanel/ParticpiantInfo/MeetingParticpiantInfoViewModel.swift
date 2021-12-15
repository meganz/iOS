

enum MeetingParticpiantInfoAction: ActionType {
    case onViewReady
    case showInfo
    case sendMessage
    case addToContact
    case makeModerator
    case removeModerator
}

struct MeetingParticpiantInfoViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case configView(email: String?, actions: [ActionSheetAction])
        case updateAvatarImage(image: UIImage)
        case updateName(name: String)
    }
    
    private let participant: CallParticipantEntity
    private let userImageUseCase: UserImageUseCaseProtocol
    private let chatRoomUseCase: ChatRoomUseCaseProtocol
    private let userInviteUseCase: UserInviteUseCaseProtocol
    private let isMyselfModerator: Bool
    private let router: MeetingParticpiantInfoViewRouting
    
    init(participant: CallParticipantEntity,
         userImageUseCase: UserImageUseCaseProtocol,
         chatRoomUseCase: ChatRoomUseCaseProtocol,
         userInviteUseCase: UserInviteUseCaseProtocol,
         isMyselfModerator: Bool,
         router: MeetingParticpiantInfoViewRouting) {
        self.participant = participant
        self.userImageUseCase = userImageUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.userInviteUseCase = userInviteUseCase
        self.isMyselfModerator = isMyselfModerator
        self.router = router
    }
    
    var invokeCommand: ((Command) -> Void)?
    
    func dispatch(_ action: MeetingParticpiantInfoAction) {
        switch action {
        case .onViewReady:
            invokeCommand?(.configView(email: participant.email, actions: actions()))
            fetchName(forParticipant: participant) { name in
                fetchUserAvatar(forParticipant: participant, name: name)
            }
        case .showInfo:
            router.showInfo()
        case .sendMessage:
            sendMessage()
        case .addToContact:
            addToContact()
        case .makeModerator:
            router.makeParticipantAsModerator()
        case .removeModerator:
            router.removeParticipantAsModerator()
        }
    }
    
    // MARK: - Private methods.
    
    private func actions() -> [ActionSheetAction] {
        if isMyselfModerator {
            if !participant.isModerator && participant.isInContactList {
                return [infoAction(), sendMessageAction(), makeModeratorAction()]
            } else if !participant.isModerator && !participant.isInContactList {
                return [makeModeratorAction()]
            } else if participant.isModerator && participant.isInContactList {
                return [infoAction(), sendMessageAction(), removeModeratorAction()]
            } else if participant.isModerator && !participant.isInContactList {
                return [removeModeratorAction()]
            } else {
                MEGALogDebug("I am a moderator and the participant is moderator \(participant.isModerator) and in contact list \(participant.isInContactList)")
            }
        } else {
            return [infoAction(), sendMessageAction()]
        }
        
        return []
    }
    
    private func fetchName(forParticipant participant: CallParticipantEntity, completion: @escaping (String) -> Void) {
        chatRoomUseCase.userDisplayName(forPeerId: participant.participantId, chatId: participant.chatId) { result in
            switch result {
            case .success(let name):
                invokeCommand?(.updateName(name: name))
                completion(name)
            case .failure(_):
                break
            }
        }
    }

    private func fetchUserAvatar(forParticipant participant: CallParticipantEntity, name: String) {
        userImageUseCase.fetchUserAvatar(withUserHandle: participant.participantId, name: name) { result in
            switch result {
            case .success(let image):
                invokeCommand?(.updateAvatarImage(image: image))
            case .failure(_):
                break
            }
        }
    }
    
    private func sendMessage() {
        if let chatRoom = chatRoomUseCase.chatRoom(forUserHandle: participant.participantId) {
            router.openChatRoom(withChatId: chatRoom.chatId)
        } else {
            chatRoomUseCase.createChatRoom(forUserHandle: participant.participantId) { result in
                if case .success(let chatRoom) = result {
                    self.router.openChatRoom(withChatId: chatRoom.chatId)
                }
            }
        }
    }
    
    private func addToContact() {
        guard let email = participant.email else { return }
        
        userInviteUseCase.sendInvite(forEmail: email) { result in
            switch result {
            case .success():
                self.router.showInviteSuccess(email: email)
            case .failure(let error):
                errorInvitingToContact(error, email: email)
            }
        }
    }
    
    private func errorInvitingToContact(_ error: InviteErrorEntity, email: String) {
        var errorString = ""
        switch error {
        case .generic(let error):
            errorString = error
        case .ownEmailEntered:
            errorString = Strings.Localizable.noNeedToAddYourOwnEmailAddress
        case .alreadyAContact:
            errorString = Strings.Localizable.alreadyAContact(email)
        case .isInOutgoingContactRequest:
            errorString = Strings.Localizable.Dialog.InviteContact.outgoingContactRequest
            errorString = errorString.replacingOccurrences(of: "[X]", with: email)
        }
        self.router.showInviteErrorMessage(errorString)
    }
        
    private func infoAction() -> ActionSheetAction {
        ActionSheetAction(title: Strings.Localizable.info,
                          detail: nil,
                          image: UIImage(named: "InfoMeetings"),
                          style: .default) {
            dispatch(.showInfo)
        }
    }
    
    private func sendMessageAction() -> ActionSheetAction {
        ActionSheetAction(title: Strings.Localizable.sendMessage,
                          detail: nil,
                          image: UIImage(named: "sendMessageMeetings"),
                          style: .default) {
            dispatch(.sendMessage)
        }
    }
    
    private func makeModeratorAction() -> ActionSheetAction {
        ActionSheetAction(title: NSLocalizedString("Make Moderator", comment: ""),
                          detail: nil,
                          image: UIImage(named: "moderatorMeetings"),
                          style: .default) {
            dispatch(.makeModerator)
        }
    }
    
    private func removeModeratorAction() -> ActionSheetAction {
        ActionSheetAction(title: NSLocalizedString("Remove Moderator", comment: ""),
                          detail: nil,
                          image: UIImage(named: "moderatorMeetings"),
                          style: .default) {
            dispatch(.removeModerator)
        }
    }
    
    private func addContactAction() -> ActionSheetAction {
        ActionSheetAction(title: Strings.Localizable.addContact,
                          detail: nil,
                          image: UIImage(named: "addContactMeetings"),
                          style: .default) {
            dispatch(.addToContact)
        }
    }
}
