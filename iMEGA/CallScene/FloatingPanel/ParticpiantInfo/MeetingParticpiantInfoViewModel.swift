

enum MeetingParticpiantInfoAction: ActionType {
    case onViewReady(imageSize: CGSize)
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
    
    private let attendee: CallParticipantEntity
    private let userImageUseCase: UserImageUseCaseProtocol
    private let chatRoomUseCase: ChatRoomUseCaseProtocol
    private let userInviteUseCase: UserInviteUseCaseProtocol
    private let isMyselfModerator: Bool
    private let router: MeetingParticpiantInfoViewRouting
    
    init(attendee: CallParticipantEntity,
         userImageUseCase: UserImageUseCaseProtocol,
         chatRoomUseCase: ChatRoomUseCaseProtocol,
         userInviteUseCase: UserInviteUseCaseProtocol,
         isMyselfModerator: Bool,
         router: MeetingParticpiantInfoViewRouting) {
        self.attendee = attendee
        self.userImageUseCase = userImageUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.userInviteUseCase = userInviteUseCase
        self.isMyselfModerator = isMyselfModerator
        self.router = router
    }
    
    var invokeCommand: ((Command) -> Void)?
    
    func dispatch(_ action: MeetingParticpiantInfoAction) {
        switch action {
        case .onViewReady(let imageSize):
            invokeCommand?(.configView(email: attendee.email, actions: actions()))
            fetchName(forParticipant: attendee) { name in
                fetchUserAvatar(forParticipant: attendee, name: name, size: imageSize)
            }
        case .showInfo:
            router.showInfo()
        case .sendMessage:
            sendMessage()
        case .addToContact:
            addToContact()
        case .makeModerator:
            router.updateAttendeeAsModerator()
        case .removeModerator:
            router.updateAttendeeAsParticipant()
        }
    }
    
    // MARK: - Private methods.
    
    private func actions() -> [ActionSheetAction] {
        if isMyselfModerator {
            if !attendee.isModerator && attendee.isInContactList {
                return [infoAction(), sendMessageAction(), makeModeratorAction()]
            } else if !attendee.isModerator && !attendee.isInContactList {
                return [makeModeratorAction()]
            } else if attendee.isModerator && attendee.isInContactList {
                return [infoAction(), sendMessageAction(), removeModeratorAction()]
            } else if attendee.isModerator && !attendee.isInContactList {
                return [removeModeratorAction()]
            } else {
                MEGALogDebug("I am a moderator and the attendee is moderator \(attendee.isModerator) and in contact list \(attendee.isInContactList)")
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

    private func fetchUserAvatar(forParticipant participant: CallParticipantEntity, name: String, size: CGSize) {
        userImageUseCase.fetchUserAvatar(withUserHandle: participant.participantId, name: name, size: size) { result in
            switch result {
            case .success(let image):
                invokeCommand?(.updateAvatarImage(image: image))
            case .failure(_):
                break
            }
        }
    }
    
    private func sendMessage() {
        if let chatRoom = chatRoomUseCase.chatRoom(forUserHandle: attendee.participantId) {
            router.openChatRoom(withChatId: chatRoom.chatId)
        } else {
            chatRoomUseCase.createChatRoom(forUserHandle: attendee.participantId) { result in
                if case .success(let chatRoom) = result {
                    self.router.openChatRoom(withChatId: chatRoom.chatId)
                }
            }
        }
    }
    
    private func addToContact() {
        guard let email = attendee.email else { return }
        
        userInviteUseCase.sendInvite(forEmail: email) { result in
            switch result {
            case .success():
                self.router.showInviteSuccess(email: email)
            case .failure(let error):
                self.router.showInviteError(error, email: email)
            }
        }
    }
        
    private func infoAction() -> ActionSheetAction {
        ActionSheetAction(title: NSLocalizedString("info", comment: ""),
                          detail: nil,
                          image: UIImage(named: "InfoMeetings"),
                          style: .default) {
            dispatch(.showInfo)
        }
    }
    
    private func sendMessageAction() -> ActionSheetAction {
        ActionSheetAction(title: NSLocalizedString("sendMessage", comment: ""),
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
        ActionSheetAction(title: NSLocalizedString("addContact", comment: ""),
                          detail: nil,
                          image: UIImage(named: "addContactMeetings"),
                          style: .default) {
            dispatch(.addToContact)
        }
    }
}
