import Combine
import MEGADomain
import MEGAL10n
import MEGAPresentation

enum ParticipantNotInCallViewAction: ActionType {
    case onViewReady
    case onCallButtonTapped
}

final class ParticipantNotInCallViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case configView(ParticipantNotInCallState, ChatStatus)
        case updateAvatarImage(image: UIImage)
        case updateName(name: String)
        case updatePrivilege(isModerator: Bool)
        case updateStatus(ChatStatus)
        case updateState(ParticipantNotInCallState)
    }
    
    private let participant: CallParticipantEntity
    private var userImageUseCase: any UserImageUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private var chatRoomUseCase: any ChatRoomUseCaseProtocol
    private var chatRoomUserUseCase: any ChatRoomUserUseCaseProtocol
    private let megaHandleUseCase: any MEGAHandleUseCaseProtocol
    private let chatUseCase: any ChatUseCaseProtocol

    private let callButtonTappedHandler: (CallParticipantEntity) -> Void
    
    private var subscriptions = Set<AnyCancellable>()
    private var avatarRefetchTask: Task<Void, Never>?
    
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
                .configView(participant.absentParticipantState.toParticipantNotInCallState(), chatStatus.toChatStatus())
            )
            fetchName(forParticipant: participant) { [weak self] name in
                guard let self else { return }
                fetchUserAvatar(forParticipant: participant, name: name)
                requestAvatarChange(forParticipant: participant)
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
                invokeCommand?(.updateStatus(statusForUser.1.toChatStatus()))
            })
            .store(in: &subscriptions)
    }
    
    private func fetchName(forParticipant participant: CallParticipantEntity, completion: @escaping (String) -> Void) {
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: participant.chatId) else {
            MEGALogDebug("ChatRoom not found for \(megaHandleUseCase.base64Handle(forUserHandle: participant.participantId) ?? "No name")")
            return
        }
        
        loadNameTask = Task { @MainActor in
            guard let name = try? await chatRoomUserUseCase.userDisplayName(forPeerId: participant.participantId, in: chatRoom) else {
                return
            }
            
            self.invokeCommand?(
                .updateName(
                    name: self.isMe ? String(format: "%@ (%@)", name, Strings.Localizable.me) : name
                )
            )
            completion(name)
        }
    }

    private func fetchUserAvatar(forParticipant participant: CallParticipantEntity, name: String) {
        guard let base64Handle = megaHandleUseCase.base64Handle(forUserHandle: participant.participantId),
              let avatarBackgroundHexColor = MEGASdk.avatarColor(forBase64UserHandle: base64Handle) else {
            MEGALogDebug("ChatRoom: base64 handle not found for handle \(participant.participantId)")
            return
        }
        
        userImageUseCase.fetchUserAvatar(withUserHandle: participant.participantId,
                                         base64Handle: base64Handle,
                                         avatarBackgroundHexColor: avatarBackgroundHexColor,
                                         name: name) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let image):
                self.invokeCommand?(.updateAvatarImage(image: image))
            case .failure(let error):
                MEGALogDebug("ChatRoom: failed to fetch avatar for \(base64Handle) - \(error)")
            }
        }
    }
    
    private func requestAvatarChange(forParticipant participant: CallParticipantEntity) {
        userImageUseCase
            .requestAvatarChangeNotification(forUserHandles: [participant.participantId])
            .sink(receiveCompletion: { error in
                MEGALogDebug("error fetching the changed avatar \(error)")
            }, receiveValue: { [weak self] _ in
                guard let self else { return }
                
                if let base64Handle = self.megaHandleUseCase.base64Handle(forUserHandle: participant.participantId) {
                    self.userImageUseCase.clearAvatarCache(base64Handle: base64Handle)
                }
                
                self.avatarRefetchTask = self.createRefetchAvatarTask(forParticipant: participant)
            })
            .store(in: &subscriptions)
    }
    
    private func createRefetchAvatarTask(forParticipant participant: CallParticipantEntity) -> Task<Void, Never> {
        Task { [weak self] in
            guard let self else { return }
            
            do {
                try await self.updateAvatarUsingName(forParticipant: participant)
                try Task.checkCancellation()
                try await self.downloadAndUpdateAvatar(forParticipant: participant)
            } catch {
                MEGALogDebug("Failed to fetch avatar for \(participant.participantId) with \(error)")
            }
        }
    }
    
    private func updateAvatarUsingName(forParticipant participant: CallParticipantEntity) async throws {
        let nameAvatar = try await createAvatarUsingName(forParticipant: participant)
        try Task.checkCancellation()
        if let nameAvatar = nameAvatar {
            await updateAvatar(image: nameAvatar)
        }
    }
    
    private func downloadAndUpdateAvatar(forParticipant participant: CallParticipantEntity) async throws {
        guard let base64Handle = megaHandleUseCase.base64Handle(forUserHandle: participant.participantId) else {
            throw UserImageLoadErrorEntity.base64EncodingError
        }
        
        let downloadedAvatar = try await userImageUseCase.fetchAvatar(base64Handle: base64Handle, forceDownload: true)
        try Task.checkCancellation()
        await updateAvatar(image: downloadedAvatar)
    }
    
    private func createAvatarUsingName(forParticipant participant: CallParticipantEntity) async throws -> UIImage? {
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: participant.chatId),
              let name = try await chatRoomUserUseCase.userDisplayNames(
                forPeerIds: [participant.participantId],
                in: chatRoom
              ).first else {
            MEGALogDebug("Unable to find the name for handle \(participant.participantId)")
            return nil
        }
        try Task.checkCancellation()
        
        guard let base64Handle = megaHandleUseCase.base64Handle(forUserHandle: participant.participantId),
              let avatarBackgroundHexColor = MEGASdk.avatarColor(forBase64UserHandle: base64Handle) else {
            return nil
        }
        let image = try await userImageUseCase.createAvatar(withUserHandle: participant.participantId,
                                                            base64Handle: base64Handle,
                                                            avatarBackgroundHexColor: avatarBackgroundHexColor,
                                                            backgroundGradientHexColor: nil,
                                                            name: name)
        return image
    }
    
    @MainActor
    private func updateAvatar(image: UIImage) {
        invokeCommand?(.updateAvatarImage(image: image))
    }
}
