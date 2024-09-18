import Combine
import MEGADesignToken
import MEGADomain
import MEGAL10n

@MainActor
final class UserAvatarViewModel: ObservableObject {
    private let userId: MEGAHandle
    private let chatId: MEGAHandle
    private let chatRoomUseCase: any ChatRoomUseCaseProtocol
    private let chatRoomUserUseCase: any ChatRoomUserUseCaseProtocol
    private var userImageUseCase: any UserImageUseCaseProtocol
    private let chatUseCase: any ChatUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private var isRightToLeftLanguage: Bool?

    @Published private(set) var primaryAvatar: UIImage?
    
    private var subscriptions = Set<AnyCancellable>()
    private var updateAvatarTask: Task<Void, Never>?
    private var loadingChatRoomAvatarTask: Task<Void, Never>?
    private var loadingAvatarSubscription: AnyCancellable?
    
    nonisolated init(userId: MEGAHandle,
                     chatId: MEGAHandle,
                     chatRoomUseCase: any ChatRoomUseCaseProtocol,
                     chatRoomUserUseCase: any ChatRoomUserUseCaseProtocol,
                     userImageUseCase: some UserImageUseCaseProtocol,
                     chatUseCase: any ChatUseCaseProtocol,
                     accountUseCase: any AccountUseCaseProtocol
    ) {
        self.userId = userId
        self.chatId = chatId
        self.chatRoomUseCase = chatRoomUseCase
        self.chatRoomUserUseCase = chatRoomUserUseCase
        self.userImageUseCase = userImageUseCase
        self.chatUseCase = chatUseCase
        self.accountUseCase = accountUseCase
    }

    // MARK: - Interface methods
    
    func loadData(isRightToLeftLanguage: Bool) {
        self.isRightToLeftLanguage = isRightToLeftLanguage
        
        loadingChatRoomAvatarTask = createLoadingChatRoomAvatarTask(isRightToLeftLanguage: isRightToLeftLanguage)
    }
    
    // MARK: - Private methods
    
    private func createLoadingChatRoomAvatarTask(isRightToLeftLanguage: Bool) -> Task<Void, Never> {
        Task { [weak self, userId] in
            do {
                try await self?.fetchAvatar(isRightToLeftLanguage: isRightToLeftLanguage)
            } catch {
                MEGALogDebug("Unable to fetch user avatar for \(userId) - \(error.localizedDescription)")
            }
        }
    }

    private func subscribeToAvatarUpdateNotification(forHandles handles: [HandleEntity]) {
        userImageUseCase
            .requestAvatarChangeNotification(forUserHandles: handles)
            .sink { [weak self] _ in
                guard let self, let isRightToLeftLanguage = self.isRightToLeftLanguage else { return }
                
                self.updateAvatarTask = Task {
                    do {
                        try await self.fetchAvatar(isRightToLeftLanguage: isRightToLeftLanguage, forceDownload: true)
                    } catch {
                        MEGALogDebug("Updating Avatar task failed for handles \(handles)")
                    }
                }
            }
            .store(in: &subscriptions)
    }
    
    private func fetchAvatar(isRightToLeftLanguage: Bool, forceDownload: Bool = false) async throws {
        if let avatar = try await createAvatar(withHandle: userId, isRightToLeftLanguage: isRightToLeftLanguage) {
            updatePrimaryAvatar(avatar)
        }
        
        subscribeToAvatarUpdateNotification(forHandles: [userId])
        try Task.checkCancellation()
        
        let downloadedAvatar = try await userAvatar(forHandle: userId, forceDownload: forceDownload)
        guard let image = UIImage(contentsOfFile: downloadedAvatar) else {
            throw UserImageLoadErrorEntity.unableToFetch
        }

        updatePrimaryAvatar(image)
    }
    
    private nonisolated func createAvatar(withHandle handle: HandleEntity, isRightToLeftLanguage: Bool, size: CGSize = CGSize(width: 100, height: 100)) async throws -> UIImage? {
        let name = try await username(forUserHandle: handle, shouldUseMeText: false)
        
        guard let base64Handle = MEGASdk.base64Handle(forUserHandle: handle),
              let avatarBackgroundHexColor = MEGASdk.avatarColor(forBase64UserHandle: base64Handle),
              let chatTitle = name else {
            return nil
        }
        
        let initials = chatTitle.initialForAvatar()
        let avatarBackgroundColor = UIColor.colorFromHexString(avatarBackgroundHexColor) ?? UIColor.black000000
        
        return UIImage.drawImage(
            forInitials: initials,
            size: size,
            backgroundColor: avatarBackgroundColor,
            textColor: TokenColors.Text.onColor,
            font: UIFont.systemFont(ofSize: min(size.width, size.height)/2.0),
            isRightToLeftLanguage: isRightToLeftLanguage)
    }
    
    private nonisolated func userAvatar(forHandle handle: HandleEntity, forceDownload: Bool = false) async throws -> ImageFilePathEntity {
        guard let base64Handle = MEGASdk.base64Handle(forUserHandle: handle) else {
            throw UserImageLoadErrorEntity.base64EncodingError
        }
        
        return try await userImageUseCase.fetchAvatar(base64Handle: base64Handle, forceDownload: false)
    }
    
    private nonisolated func username(forUserHandle userHandle: HandleEntity, shouldUseMeText: Bool) async throws -> String? {
        if userHandle == accountUseCase.currentUserHandle {
            return shouldUseMeText ? Strings.Localizable.me : chatUseCase.myFullName()
        } else {
            guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatId) else { return nil }
            let usernames = try await chatRoomUserUseCase.userDisplayNames(forPeerIds: [userHandle], in: chatRoom)
            return usernames.first
        }
    }
    
    private func updatePrimaryAvatar(_ avatar: UIImage) {
        primaryAvatar = avatar
    }
}
