import MEGAAppPresentation
import MEGADomain
import MEGAL10n

enum MeetingParticipantInfoAction: ActionType {
    case onViewReady
    case showInfo
    case sendMessage
    case makeModerator
    case removeModerator
    case removeParticipant
    case displayInMainView
    case muteParticipant
}

final class MeetingParticipantInfoViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case configView(actions: [ActionSheetAction])
        case updateAvatarImage(image: UIImage)
        case updateName(name: String)
        case updateEmail(email: String?)
    }
    
    private let participant: CallParticipantEntity
    private let userImageUseCase: any UserImageUseCaseProtocol
    private let chatRoomUseCase: any ChatRoomUseCaseProtocol
    private let chatRoomUserUseCase: any ChatRoomUserUseCaseProtocol
    private let megaHandleUseCase: any MEGAHandleUseCaseProtocol
    private let contactsUseCase: any ContactsUseCaseProtocol
    private let isMyselfModerator: Bool
    private let router: any MeetingParticipantInfoViewRouting
    private var email: String?
    
    init(participant: CallParticipantEntity,
         userImageUseCase: some UserImageUseCaseProtocol,
         chatRoomUseCase: some ChatRoomUseCaseProtocol,
         chatRoomUserUseCase: some ChatRoomUserUseCaseProtocol,
         megaHandleUseCase: some MEGAHandleUseCaseProtocol,
         contactsUseCase: some ContactsUseCaseProtocol,
         isMyselfModerator: Bool,
         router: some MeetingParticipantInfoViewRouting) {
        self.participant = participant
        self.userImageUseCase = userImageUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.chatRoomUserUseCase = chatRoomUserUseCase
        self.megaHandleUseCase = megaHandleUseCase
        self.contactsUseCase = contactsUseCase
        self.isMyselfModerator = isMyselfModerator
        self.router = router
    }
    
    var invokeCommand: ((Command) -> Void)?
    
    func dispatch(_ action: MeetingParticipantInfoAction) {
        switch action {
        case .onViewReady:
            invokeCommand?(.configView(actions: actions()))
            Task { @MainActor in
                email = await chatRoomUseCase.userEmail(for: participant.participantId)
                invokeCommand?(.updateEmail(email: email))
                fetchName(forParticipant: participant)
            }
        case .showInfo:
            router.showInfo(withEmail: email)
        case .sendMessage:
            sendMessage()
        case .makeModerator:
            router.makeParticipantAsModerator()
        case .removeModerator:
            router.removeModeratorPrivilege()
        case .removeParticipant:
            router.removeParticipant()
        case .displayInMainView:
            router.displayInMainView()
        case .muteParticipant:
            router.muteParticipant(participant)
        }
    }
    
    // MARK: - Private methods.
    
    private func actions() -> [ActionSheetAction] {
        var actions: [ActionSheetAction] = []
        
        if contactsUseCase.contact(forUserHandle: participant.participantId) != nil {
            actions.append(contentsOf: [infoAction(), sendMessageAction()])
        }
                
        if isMyselfModerator {
            if participant.audio == .on {
                actions.append(muteParticipantAction())
            }
            if participant.isModerator {
                actions.append(removeModeratorAction())
            } else {
                actions.append(makeModeratorAction())
            }
        }
        
        if !participant.isSpeakerPinned {
            actions.append(displayInMainViewAction())
        }
        
        if isMyselfModerator {
            actions.append(removeContactAction())
        }
        
        return actions
    }
    
    private func fetchName(forParticipant participant: CallParticipantEntity) {
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: participant.chatId) else { return }
        
        Task { @MainActor in
            guard let name = try? await chatRoomUserUseCase.userDisplayName(forPeerId: participant.participantId, in: chatRoom) else {
                return
            }
            
            participant.name = name
            invokeCommand?(.updateName(name: name))
            fetchUserAvatar(forParticipant: participant, name: name)
        }
    }

    private func fetchUserAvatar(forParticipant participant: CallParticipantEntity, name: String) {
        guard let base64Handle = megaHandleUseCase.base64Handle(forUserHandle: participant.participantId),
              let avatarBackgroundHexColor = MEGASdk.avatarColor(forBase64UserHandle: base64Handle) else {
            return
        }
                
        let avatarHandler = UserAvatarHandler(
            userImageUseCase: userImageUseCase,
            initials: name.initialForAvatar(),
            avatarBackgroundColor: UIColor.colorFromHexString(avatarBackgroundHexColor) ?? .black000000
        )
        
        Task { @MainActor in
            let image = await avatarHandler.avatar(for: base64Handle)
            invokeCommand?(.updateAvatarImage(image: image))
            
        }
    }
    
    private func sendMessage() {
        if let chatRoom = chatRoomUseCase.chatRoom(forUserHandle: participant.participantId) {
            router.openChatRoom(chatRoom)
        } else {
            Task { @MainActor in
                let newChatRoom = try await chatRoomUseCase.createChatRoom(forUserHandle: participant.participantId)
                router.openChatRoom(newChatRoom)
            }
        }
    }
        
    private func infoAction() -> ActionSheetAction {
        ActionSheetAction(title: Strings.Localizable.info,
                          detail: nil,
                          image: UIImage(resource: .infoMeetings),
                          style: .default) { [weak self] in
            self?.dispatch(.showInfo)
        }
    }
    
    private func sendMessageAction() -> ActionSheetAction {
        ActionSheetAction(title: Strings.Localizable.sendMessage,
                          detail: nil,
                          image: UIImage(resource: .sendMessageMeetings),
                          style: .default) { [weak self] in
            self?.dispatch(.sendMessage)
        }
    }
    
    private func makeModeratorAction() -> ActionSheetAction {
        ActionSheetAction(title: Strings.Localizable.Meetings.Participant.makeModerator,
                          detail: nil,
                          image: UIImage(resource: .moderatorMeetings),
                          style: .default) { [weak self] in
            self?.dispatch(.makeModerator)
        }
    }
    
    private func removeModeratorAction() -> ActionSheetAction {
        ActionSheetAction(title: Strings.Localizable.Meetings.Participant.removeModerator,
                          detail: nil,
                          image: UIImage(resource: .removeModerator),
                          style: .default) { [weak self] in
            self?.dispatch(.removeModerator)
        }
    }
    
    private func removeContactAction() -> ActionSheetAction {
        ActionSheetAction(title: Strings.Localizable.removeParticipant,
                          detail: nil,
                          image: UIImage(resource: .delete),
                          style: .destructive) { [weak self] in
            self?.dispatch(.removeParticipant)
        }
    }
    
    private func displayInMainViewAction() -> ActionSheetAction {
        ActionSheetAction(title: Strings.Localizable.Meetings.DisplayInMainView.title,
                          detail: nil,
                          image: UIImage(resource: .speakerView),
                          style: .default) { [weak self] in
            self?.dispatch(.displayInMainView)
        }
    }
    
    private func muteParticipantAction() -> ActionSheetAction {
        ActionSheetAction(title: Strings.Localizable.Calls.Panel.ParticipantsInCall.ParticipantContextMenu.Actions.mute,
                          detail: nil,
                          image: UIImage(resource: .muteParticipant),
                          style: .default) { [weak self] in
            self?.dispatch(.muteParticipant)
        }
    }
}
