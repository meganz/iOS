import Combine
import MEGADomain
import MEGAL10n
import MEGAPresentation

enum ParticipantNotInCallViewAction: ActionType {
    case onViewReady
    case onCallButtonTapped
}

@MainActor
final class ParticipantNotInCallViewModel: ViewModelType, CommonParticipantViewModel {
    enum Command: CommandType, Equatable {
        case configView(ParticipantNotInCallState, ChatStatusEntity)
        case updateAvatarImage(image: UIImage)
        case updateName(name: String)
        case updatePrivilege(isModerator: Bool)
        case updateStatus(ChatStatusEntity)
        case updateState(ParticipantNotInCallState)
    }
    
    let participant: CallParticipantEntity
    var userImageUseCase: any UserImageUseCaseProtocol
    let accountUseCase: any AccountUseCaseProtocol
    var chatRoomUseCase: any ChatRoomUseCaseProtocol
    var chatRoomUserUseCase: any ChatRoomUserUseCaseProtocol
    let megaHandleUseCase: any MEGAHandleUseCaseProtocol
    private let chatUseCase: any ChatUseCaseProtocol

    private let callButtonTappedHandler: (CallParticipantEntity) -> Void
    
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
         chatUseCase: some ChatUseCaseProtocol,
         callButtonTappedHandler: @escaping (CallParticipantEntity) -> Void) {
        self.participant = participant
        self.userImageUseCase = userImageUseCase
        self.accountUseCase = accountUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.chatRoomUserUseCase = chatRoomUserUseCase
        self.megaHandleUseCase = megaHandleUseCase
        self.chatUseCase = chatUseCase
        self.callButtonTappedHandler = callButtonTappedHandler
    }
    
    deinit {
        avatarRefetchTask?.cancel()
        loadNameTask?.cancel()
    }
    
    func dispatch(_ action: ParticipantNotInCallViewAction) {
        switch action {
        case .onViewReady:
            let chatStatus = chatRoomUseCase.userStatus(forUserHandle: participant.participantId)
            listeningForChatStatusUpdate()
            invokeCommand?(
                .configView(participant.absentParticipantState.toParticipantNotInCallState(), chatStatus)
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
        case .onCallButtonTapped:
            callButtonTappedHandler(participant)
        }
    }
    
    private func listeningForChatStatusUpdate() {
        chatUseCase
            .monitorChatStatusChange()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { error in
                MEGALogDebug("error fetching the changed status \(error)")
            }, receiveValue: { [weak self] statusForUser in
                guard let self, statusForUser.0 == self.participant.participantId else { return }
                invokeCommand?(.updateStatus(statusForUser.1))
            })
            .store(in: &subscriptions)
    }
    
    func updateAvatar(image: UIImage) {
        invokeCommand?(.updateAvatarImage(image: image))
    }
}

public extension AbsentParticipantState {
    func toParticipantNotInCallState() -> ParticipantNotInCallState {
        switch self {
        case .notInCall: .notInCall
        case .calling: .calling
        case .noResponse: .noResponse
        }
    }
}
