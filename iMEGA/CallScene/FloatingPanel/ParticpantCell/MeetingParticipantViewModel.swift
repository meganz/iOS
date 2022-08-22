import Combine
import MEGADomain

enum MeetingParticipantViewAction: ActionType {
    case onViewReady
    case contextMenuTapped(button: UIButton)
}

final class MeetingParticipantViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case configView(isModerator: Bool, isMicMuted: Bool, isVideoOn: Bool, shouldHideContextMenu: Bool)
        case updateAvatarImage(image: UIImage)
        case updateName(name: String)
        case updatePrivilege(isModerator: Bool)
    }
    
    private let participant: CallParticipantEntity
    private var userImageUseCase: UserImageUseCaseProtocol
    private let userUseCase: UserUseCaseProtocol
    private var chatRoomUseCase: ChatRoomUseCaseProtocol
    private let contextMenuTappedHandler: (CallParticipantEntity, UIButton) -> Void
    
    private var subscriptions = Set<AnyCancellable>()
    private var avatarRefetchTask: Task<Void, Never>?
    
    private var shouldHideContextMenu: Bool {
        if userUseCase.isGuest {
            return true
        }
        
        return isMe || isOneToOneChat
    }
    
    private var isMe: Bool {
        return userUseCase.myHandle == participant.participantId
    }
    
    private var isOneToOneChat: Bool {
        return chatRoomUseCase.chatRoom(forChatId: participant.chatId)?.chatType == .oneToOne
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
    
    deinit {
        avatarRefetchTask?.cancel()
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
            fetchName(forParticipant: participant) { [weak self] name in
                guard let self = self else { return }
                self.fetchUserAvatar(forParticipant: self.participant, name: name)
                self.requestAvatarChange(forParticipant: self.participant, name: name)
            }
        case .contextMenuTapped(let button):
            contextMenuTappedHandler(participant, button)
        }
    }
    
    private func fetchName(forParticipant participant: CallParticipantEntity, completion: @escaping (String) -> Void) {
        chatRoomUseCase.userDisplayName(forPeerId: participant.participantId, chatId: participant.chatId) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let name):
                self.invokeCommand?(
                    .updateName(
                        name: self.isMe ? String(format: "%@ (%@)", name, Strings.Localizable.me) : name
                    )
                )
                completion(name)
            case .failure(let error):
                MEGALogDebug("ChatRoom: failed to get the user display name for \(MEGASdk.base64Handle(forUserHandle: participant.participantId) ?? "No name") - \(error)")
            }
        }
    }

    private func fetchUserAvatar(forParticipant participant: CallParticipantEntity, name: String) {
        userImageUseCase.fetchUserAvatar(withUserHandle: participant.participantId, name: name) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let image):
                self.invokeCommand?(.updateAvatarImage(image: image))
            case .failure(let error):
                MEGALogDebug("ChatRoom: failed to fetch avatar for \(MEGASdk.base64Handle(forUserHandle: participant.participantId) ?? "No name") - \(error)")
            }
        }
    }
    
    private func requestAvatarChange(forParticipant participant: CallParticipantEntity, name: String) {
        userImageUseCase
            .requestAvatarChangeNotification(forUserHandles: [participant.participantId])
            .sink(receiveCompletion: { error in
                MEGALogDebug("error fetching the changed avatar \(error)")
            }, receiveValue: { [weak self] _ in
                guard let self = self else { return }
                self.userImageUseCase.clearAvatarCache(forUserHandle: participant.participantId)
                self.avatarRefetchTask = self.createRefetchAvatarTask(forParticipant: participant)
            })
            .store(in: &subscriptions)
    }
    
    private func createRefetchAvatarTask(forParticipant participant: CallParticipantEntity) -> Task<Void, Never> {
        Task { [weak self] in
            guard let self = self else { return }
            
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
        let downloadedAvatar = try await userImageUseCase.downloadAvatar(forUserHandle: participant.participantId)
        try Task.checkCancellation()
        await updateAvatar(image: downloadedAvatar)
    }
    
    private func createAvatarUsingName(forParticipant participant: CallParticipantEntity) async throws -> UIImage? {
        guard let name = try await chatRoomUseCase.userDisplayNames(
            forPeerIds: [participant.participantId],
            chatId: participant.chatId
        ).first else {
            MEGALogDebug("Unable to find the name for handle \(participant.participantId)")
            return nil
        }
        try Task.checkCancellation()
        
        let image = try await userImageUseCase.createAvatar(
            usingUserHandle: participant.participantId, name: name
        )
        
        return image
    }
    
    @MainActor
    private func updateAvatar(image: UIImage) {
        invokeCommand?(.updateAvatarImage(image: image))
    }
}

