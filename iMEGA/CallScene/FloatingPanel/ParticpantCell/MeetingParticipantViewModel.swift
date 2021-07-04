
enum MeetingParticipantViewAction: ActionType {
    case onViewReady(imageSize: CGSize)
    case contextMenuTapped(button: UIButton)
}

struct MeetingParticipantViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case configView(isModerator: Bool, isMicMuted: Bool, isVideoOn: Bool, shouldHideContextMenu: Bool)
        case updateAvatarImage(image: UIImage)
        case updateName(name: String, isMe: Bool)
    }
    
    private let attendee: CallParticipantEntity
    private let userImageUseCase: UserImageUseCaseProtocol
    private let userUseCase: UserUseCaseProtocol
    private let chatRoomUseCase: ChatRoomUseCaseProtocol
    private let contextMenuTappedHandler: (CallParticipantEntity, UIButton) -> Void
    
    private var shouldHideContextMenu: Bool {
        if userUseCase.isGuestAccount {
            return true
        }
        
        return isMe || attendee.attendeeType == .guest
    }
    
    private var isMe: Bool {
        return userUseCase.myHandle == attendee.participantId
    }
    
    var invokeCommand: ((Command) -> Void)?
    
    init(attendee: CallParticipantEntity,
         userImageUseCase: UserImageUseCaseProtocol,
         userUseCase: UserUseCaseProtocol,
         chatRoomUseCase: ChatRoomUseCaseProtocol,
         contextMenuTappedHandler: @escaping (CallParticipantEntity, UIButton) -> Void) {
        self.attendee = attendee
        self.userImageUseCase = userImageUseCase
        self.userUseCase = userUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.contextMenuTappedHandler = contextMenuTappedHandler
    }
    
    func dispatch(_ action: MeetingParticipantViewAction) {
        switch action {
        case .onViewReady(let imageSize):
            invokeCommand?(
                .configView(isModerator: attendee.attendeeType == .moderator,
                            isMicMuted: attendee.audio == .off,
                            isVideoOn: attendee.video == .on,
                            shouldHideContextMenu: shouldHideContextMenu)
            )
            fetchName(forParticipant: attendee) { name in
                fetchUserAvatar(forParticipant: attendee, name: name, size: imageSize)
            }
        case .contextMenuTapped(let button):
            contextMenuTappedHandler(attendee, button)
        }
    }
    
    private func fetchName(forParticipant participant: CallParticipantEntity, completion: @escaping (String) -> Void) {
        chatRoomUseCase.userDisplayName(forPeerId: participant.participantId, chatId: participant.chatId) { result in
            switch result {
            case .success(let name):
                invokeCommand?(.updateName(name: name, isMe: isMe))
                completion(name)
            case .failure(let error):
                MEGALogDebug("ChatRoom: failed to get the user display name for \(participant.participantId) - \(error)")
            }
        }
    }

    private func fetchUserAvatar(forParticipant participant: CallParticipantEntity, name: String, size: CGSize) {
        userImageUseCase.fetchUserAvatar(withUserHandle: participant.participantId, name: name, size: size) { result in
            switch result {
            case .success(let image):
                invokeCommand?(.updateAvatarImage(image: image))
            case .failure(let error):
                MEGALogDebug("ChatRoom: failed to fetch avatar for \(participant.participantId) - \(error)")
            }
        }
    }
}

