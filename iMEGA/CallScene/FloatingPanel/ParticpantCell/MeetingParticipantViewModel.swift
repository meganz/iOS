
enum MeetingParticipantViewAction: ActionType {
    case onViewReady
    case contextMenuTapped(button: UIButton)
}

struct MeetingParticipantViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case configView(isModerator: Bool, isMicMuted: Bool, isVideoOn: Bool, shouldHideContextMenu: Bool)
        case updateAvatarImage(image: UIImage)
        case updateName(name: String)
    }
    
    private let participant: CallParticipantEntity
    private let userImageUseCase: UserImageUseCaseProtocol
    private let userUseCase: UserUseCaseProtocol
    private let chatRoomUseCase: ChatRoomUseCaseProtocol
    private let contextMenuTappedHandler: (CallParticipantEntity, UIButton) -> Void
    
    private var shouldHideContextMenu: Bool {
        if userUseCase.isGuest {
            return true
        }
        
        return isMe || (!isMyselfModerator && !participant.isInContactList) || isOneToOneChat
    }
    
    private var isMe: Bool {
        return userUseCase.myHandle == participant.participantId
    }
    
    private var isOneToOneChat: Bool {
        return chatRoomUseCase.chatRoom(forChatId: participant.chatId)?.chatType == .oneToOne
    }
    
    private var isMyselfModerator: Bool {
        guard let chatRoomEntity = chatRoomUseCase.chatRoom(forChatId: participant.chatId) else {
            return false
        }
        
        return chatRoomEntity.ownPrivilege == .moderator
    }
    
    var invokeCommand: ((Command) -> Void)?
    
    init(participant: CallParticipantEntity,
         userImageUseCase: UserImageUseCaseProtocol,
         userUseCase: UserUseCaseProtocol,
         chatRoomUseCase: ChatRoomUseCaseProtocol,
         contextMenuTappedHandler: @escaping (CallParticipantEntity, UIButton) -> Void) {
        self.participant = participant
        self.userImageUseCase = userImageUseCase
        self.userUseCase = userUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.contextMenuTappedHandler = contextMenuTappedHandler
    }
    
    func dispatch(_ action: MeetingParticipantViewAction) {
        switch action {
        case .onViewReady:
            invokeCommand?(
                .configView(isModerator: participant.isModerator && !isOneToOneChat,
                            isMicMuted: participant.audio == .off,
                            isVideoOn: participant.video == .on,
                            shouldHideContextMenu: shouldHideContextMenu)
            )
            fetchName(forParticipant: participant) { name in
                fetchUserAvatar(forParticipant: participant, name: name)
            }
        case .contextMenuTapped(let button):
            contextMenuTappedHandler(participant, button)
        }
    }
    
    private func fetchName(forParticipant participant: CallParticipantEntity, completion: @escaping (String) -> Void) {
        chatRoomUseCase.userDisplayName(forPeerId: participant.participantId, chatId: participant.chatId) { result in
            switch result {
            case .success(let name):
                invokeCommand?(
                    .updateName(
                        name: isMe ? String(format: "%@ (%@)", name, Strings.Localizable.me) : name
                    )
                )
                completion(name)
            case .failure(let error):
                MEGALogDebug("ChatRoom: failed to get the user display name for \(MEGASdk.base64Handle(forUserHandle: participant.participantId) ?? "No name") - \(error)")
            }
        }
    }

    private func fetchUserAvatar(forParticipant participant: CallParticipantEntity, name: String) {
        userImageUseCase.fetchUserAvatar(withUserHandle: participant.participantId, name: name) { result in
            switch result {
            case .success(let image):
                invokeCommand?(.updateAvatarImage(image: image))
            case .failure(let error):
                MEGALogDebug("ChatRoom: failed to fetch avatar for \(MEGASdk.base64Handle(forUserHandle: participant.participantId) ?? "No name") - \(error)")
            }
        }
    }
}

