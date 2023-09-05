import MEGADomain
import MEGAL10n
import MEGAPresentation

enum MeetingParticpiantInfoAction: ActionType {
    case onViewReady
    case showInfo
    case sendMessage
    case makeModerator
    case removeModerator
    case removeParticipant
    case displayInMainView
}

struct MeetingParticpiantInfoViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case configView(email: String?, actions: [ActionSheetAction])
        case updateAvatarImage(image: UIImage)
        case updateName(name: String)
    }
    
    private let participant: CallParticipantEntity
    private let userImageUseCase: any UserImageUseCaseProtocol
    private let chatRoomUseCase: any ChatRoomUseCaseProtocol
    private let chatRoomUserUseCase: any ChatRoomUserUseCaseProtocol
    private let megaHandleUseCase: any MEGAHandleUseCaseProtocol
    private let isMyselfModerator: Bool
    private let router: any MeetingParticpiantInfoViewRouting
    
    init(participant: CallParticipantEntity,
         userImageUseCase: some UserImageUseCaseProtocol,
         chatRoomUseCase: some ChatRoomUseCaseProtocol,
         chatRoomUserUseCase: some ChatRoomUserUseCaseProtocol,
         megaHandleUseCase: some MEGAHandleUseCaseProtocol,
         isMyselfModerator: Bool,
         router: some MeetingParticpiantInfoViewRouting) {
        self.participant = participant
        self.userImageUseCase = userImageUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.chatRoomUserUseCase = chatRoomUserUseCase
        self.megaHandleUseCase = megaHandleUseCase
        self.isMyselfModerator = isMyselfModerator
        self.router = router
    }
    
    var invokeCommand: ((Command) -> Void)?
    
    func dispatch(_ action: MeetingParticpiantInfoAction) {
        switch action {
        case .onViewReady:
            invokeCommand?(.configView(email: participant.email, actions: actions()))
            fetchName(forParticipant: participant)
        case .showInfo:
            router.showInfo()
        case .sendMessage:
            sendMessage()
        case .makeModerator:
            router.makeParticipantAsModerator()
        case .removeModerator:
            router.removeModeratorPrivilage()
        case .removeParticipant:
            router.removeParticipant()
        case .displayInMainView:
            router.displayInMainView()
        }
    }
    
    // MARK: - Private methods.
    
    private func actions() -> [ActionSheetAction] {
        var actions: [ActionSheetAction] = []
        
        if participant.isInContactList {
            actions.append(contentsOf: [infoAction(), sendMessageAction()])
        }
                
        if isMyselfModerator {
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
            
            invokeCommand?(.updateName(name: name))
            fetchUserAvatar(forParticipant: participant, name: name)
        }
    }

    private func fetchUserAvatar(forParticipant participant: CallParticipantEntity, name: String) {
        guard let base64Handle = megaHandleUseCase.base64Handle(forUserHandle: participant.participantId),
              let avatarBackgroundHexColor = MEGASdk.avatarColor(forBase64UserHandle: base64Handle) else {
            return
        }
        
        userImageUseCase.fetchUserAvatar(withUserHandle: participant.participantId,
                                         base64Handle: base64Handle,
                                         avatarBackgroundHexColor: avatarBackgroundHexColor,
                                         name: name) { result in
            switch result {
            case .success(let image):
                invokeCommand?(.updateAvatarImage(image: image))
            case .failure:
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
        
    private func infoAction() -> ActionSheetAction {
        ActionSheetAction(title: Strings.Localizable.info,
                          detail: nil,
                          image: Asset.Images.Meetings.infoMeetings.image,
                          style: .default) {
            dispatch(.showInfo)
        }
    }
    
    private func sendMessageAction() -> ActionSheetAction {
        ActionSheetAction(title: Strings.Localizable.sendMessage,
                          detail: nil,
                          image: Asset.Images.Meetings.sendMessageMeetings.image,
                          style: .default) {
            dispatch(.sendMessage)
        }
    }
    
    private func makeModeratorAction() -> ActionSheetAction {
        ActionSheetAction(title: Strings.Localizable.Meetings.Participant.makeModerator,
                          detail: nil,
                          image: Asset.Images.Meetings.moderatorMeetings.image,
                          style: .default) {
            dispatch(.makeModerator)
        }
    }
    
    private func removeModeratorAction() -> ActionSheetAction {
        ActionSheetAction(title: Strings.Localizable.Meetings.Participant.removeModerator,
                          detail: nil,
                          image: Asset.Images.Meetings.removeModerator.image,
                          style: .default) {
            dispatch(.removeModerator)
        }
    }
    
    private func removeContactAction() -> ActionSheetAction {
        ActionSheetAction(title: Strings.Localizable.removeParticipant,
                          detail: nil,
                          image: Asset.Images.NodeActions.delete.image,
                          style: .destructive) {
            dispatch(.removeParticipant)
        }
    }
    
    private func displayInMainViewAction() -> ActionSheetAction {
        ActionSheetAction(title: Strings.Localizable.Meetings.DisplayInMainView.title,
                          detail: nil,
                          image: Asset.Images.Chat.speakerView.image,
                          style: .default) {
            dispatch(.displayInMainView)
        }
    }
}
