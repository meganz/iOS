import Combine
import MEGAAppPresentation
import MEGADomain
import MEGAL10n

enum MeetingParticipantViewAction: ActionType {
    case onViewReady
    case contextMenuTapped(button: UIButton)
}

@MainActor
final class MeetingParticipantViewModel: ViewModelType, CommonParticipantViewModel {
    enum Command: CommandType, Equatable {
        case configView(isModerator: Bool, isMicMuted: Bool, isVideoOn: Bool, shouldHideContextMenu: Bool, raisedHand: Bool)
        case updateAvatarImage(image: UIImage)
        case updateName(name: String)
        case updatePrivilege(isModerator: Bool)
    }
    
    let participant: CallParticipantEntity
    var userImageUseCase: any UserImageUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    var chatRoomUseCase: any ChatRoomUseCaseProtocol
    var chatRoomUserUseCase: any ChatRoomUserUseCaseProtocol
    let megaHandleUseCase: any MEGAHandleUseCaseProtocol
    private let contextMenuTappedHandler: (CallParticipantEntity, UIButton) -> Void
    
    var subscriptions = Set<AnyCancellable>()
    var avatarRefetchTask: Task<Void, Never>?
    
    private var shouldHideContextMenu: Bool {
        if accountUseCase.isGuest {
            return true
        }
        
        return isMe || isOneToOneChat
    }
    
    private var isMe: Bool {
        accountUseCase.currentUserHandle == participant.participantId
    }
    
    private var isOneToOneChat: Bool {
        return chatRoomUseCase.chatRoom(forChatId: participant.chatId)?.chatType == .oneToOne
    }
    
    var invokeCommand: ((Command) -> Void)?
    var loadNameTask: Task<Void, Never>?
    
    init(participant: CallParticipantEntity,
         userImageUseCase: some UserImageUseCaseProtocol,
         accountUseCase: some AccountUseCaseProtocol,
         chatRoomUseCase: some ChatRoomUseCaseProtocol,
         chatRoomUserUseCase: some ChatRoomUserUseCaseProtocol,
         megaHandleUseCase: some MEGAHandleUseCaseProtocol,
         contextMenuTappedHandler: @escaping (CallParticipantEntity, UIButton) -> Void) {
        self.participant = participant
        self.userImageUseCase = userImageUseCase
        self.accountUseCase = accountUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.chatRoomUserUseCase = chatRoomUserUseCase
        self.megaHandleUseCase = megaHandleUseCase
        self.contextMenuTappedHandler = contextMenuTappedHandler
    }
    
    deinit {
        avatarRefetchTask?.cancel()
        loadNameTask?.cancel()
    }
    
    func dispatch(_ action: MeetingParticipantViewAction) {
        switch action {
        case .onViewReady:
            invokeCommand?(
                .configView(isModerator: participant.isModerator && !isOneToOneChat,
                            isMicMuted: participant.audio == .off,
                            isVideoOn: participant.video == .on,
                            shouldHideContextMenu: shouldHideContextMenu,
                            raisedHand: participant.raisedHand)
            )
            loadNameTask = Task { @MainActor [weak self] in
                guard let self else { return }
                if let name = await fetchName() {
                    invokeCommand?(
                        .updateName(name: isMe ? String(format: "%@ (%@)", name, Strings.Localizable.me) : name)
                    )
                    if let image = await fetchUserAvatar(name: name) {
                        invokeCommand?(.updateAvatarImage(image: image))
                    }
                }
                    
                requestAvatarChange()
            }
        case .contextMenuTapped(let button):
            contextMenuTappedHandler(participant, button)
        }
    }
    
    func updateAvatar(image: UIImage) {
        invokeCommand?(.updateAvatarImage(image: image))
    }
}
