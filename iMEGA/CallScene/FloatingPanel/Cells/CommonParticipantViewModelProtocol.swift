import Combine
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASwift

protocol CommonParticipantViewModel: AnyObject, Sendable {
    var participant: CallParticipantEntity { get }
    var userImageUseCase: any UserImageUseCaseProtocol { get set }
    var chatRoomUseCase: any ChatRoomUseCaseProtocol { get }
    var chatRoomUserUseCase: any ChatRoomUserUseCaseProtocol { get }
    var megaHandleUseCase: any MEGAHandleUseCaseProtocol { get }
    
    var subscriptions: Set<AnyCancellable> { get set }
    var avatarRefetchTask: Task<Void, Never>? { get set }
    var loadNameTask: Task<Void, Never>? { get set }
    
    func fetchName() async -> String?
    func fetchUserAvatar(name: String) async -> UIImage?
    func requestAvatarChange()
    func createRefetchAvatarTask() -> Task<Void, Never>
    func updateAvatarUsingName() async throws
    func downloadAndUpdateAvatar() async throws
    func updateAvatar(image: UIImage)
}

extension CommonParticipantViewModel {
    func fetchName() async -> String? {
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: participant.chatId) else {
            MEGALogDebug("ChatRoom not found for \(megaHandleUseCase.base64Handle(forUserHandle: participant.participantId) ?? "No name")")
            return nil
        }
        
        do {
            return try await chatRoomUserUseCase.userDisplayName(forPeerId: participant.participantId, in: chatRoom)
        } catch {
            return nil
        }
    }

    func fetchUserAvatar(name: String) async -> UIImage? {
        guard let base64Handle = megaHandleUseCase.base64Handle(forUserHandle: participant.participantId),
              let avatarBackgroundHexColor = userImageUseCase.avatarColorHex(forBase64UserHandle: base64Handle) else {
            MEGALogDebug("ChatRoom: base64 handle not found for handle \(participant.participantId)")
            return nil
        }
        
        let avatarHandler = UserAvatarHandler(
            userImageUseCase: userImageUseCase,
            initials: name.initialForAvatar(),
            avatarBackgroundColor: UIColor.colorFromHexString(avatarBackgroundHexColor) ?? .black000000
        )
        
        return await avatarHandler.avatar(for: base64Handle)
    }
    
    func requestAvatarChange() {
        userImageUseCase
            .requestAvatarChangeNotification(forUserHandles: [participant.participantId])
            .sink(receiveCompletion: { error in
                MEGALogDebug("error fetching the changed avatar \(error)")
            }, receiveValue: { [weak self] _ in
                guard let self else { return }
                if let base64Handle = megaHandleUseCase.base64Handle(forUserHandle: participant.participantId) {
                    userImageUseCase.clearAvatarCache(base64Handle: base64Handle)
                }
                
                avatarRefetchTask = createRefetchAvatarTask()
            })
            .store(in: &subscriptions)
    }
    
    func createRefetchAvatarTask() -> Task<Void, Never> {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await updateAvatarUsingName()
                try Task.checkCancellation()
                try await downloadAndUpdateAvatar()
            } catch {
                MEGALogDebug("Failed to fetch avatar with error: \(error)")
            }
        }
    }
    
    @MainActor
    func updateAvatarUsingName() async throws {
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: participant.chatId),
              let name = try await chatRoomUserUseCase.userDisplayNames(
                forPeerIds: [participant.participantId],
                in: chatRoom
              ).first else {
            MEGALogDebug("Unable to find the name for handle \(participant.participantId)")
            return
        }
        let avatarImage = await fetchUserAvatar(name: name)
        try Task.checkCancellation()
        if let avatarImage {
            updateAvatar(image: avatarImage)
        }
    }
    
    @MainActor
    func downloadAndUpdateAvatar() async throws {
        guard let base64Handle = megaHandleUseCase.base64Handle(forUserHandle: participant.participantId) else {
            throw UserImageLoadErrorEntity.base64EncodingError
        }
        
        let downloadedAvatar = try await userImageUseCase.fetchAvatar(base64Handle: base64Handle, forceDownload: true)
        try Task.checkCancellation()
        guard let image = UIImage(contentsOfFile: downloadedAvatar) else {
            throw UserImageLoadErrorEntity.unableToFetch
        }
        updateAvatar(image: image)
    }
}
