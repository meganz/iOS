import Combine
import MEGADomain

final class ChatRoomAvatarViewModel: ObservableObject {
    let title: String
    let peerHandle: HandleEntity
    let chatRoomEntity: ChatRoomEntity
    private let chatRoomUseCase: any ChatRoomUseCaseProtocol
    private let chatRoomUserUseCase: any ChatRoomUserUseCaseProtocol
    private var userImageUseCase: UserImageUseCaseProtocol
    private let chatUseCase: any ChatUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private let megaHandleUseCase: any MEGAHandleUseCaseProtocol
    private var isRightToLeftLanguage: Bool?
    
    @Published private(set) var primaryAvatar: UIImage?
    @Published private(set) var secondaryAvatar: UIImage?
    
    private var subscriptions = Set<AnyCancellable>()
    private var loadingChatRoomAvatarTask: Task<Void, Never>?
    private var loadingAvatarSubscription: AnyCancellable?
    private var shouldLoadAvatar = true
    
    init(
        title: String,
        peerHandle: HandleEntity,
        chatRoomEntity: ChatRoomEntity,
        chatRoomUseCase: any ChatRoomUseCaseProtocol,
        chatRoomUserUseCase: any ChatRoomUserUseCaseProtocol,
        userImageUseCase: UserImageUseCaseProtocol,
        chatUseCase: any ChatUseCaseProtocol,
        accountUseCase: any AccountUseCaseProtocol,
        megaHandleUseCase: any MEGAHandleUseCaseProtocol
    ) {
        self.title = title
        self.peerHandle = peerHandle
        self.chatRoomEntity = chatRoomEntity
        self.chatRoomUseCase = chatRoomUseCase
        self.chatRoomUserUseCase = chatRoomUserUseCase
        self.userImageUseCase = userImageUseCase
        self.chatUseCase = chatUseCase
        self.accountUseCase = accountUseCase
        self.megaHandleUseCase = megaHandleUseCase
    }
    
    // MARK: - Interface methods
    
    func loadAvatar(isRightToLeftLanguage: Bool) {
        self.isRightToLeftLanguage = isRightToLeftLanguage
        
        loadChatRoomAvatarIfNeeded(isRightToLeftLanguage: isRightToLeftLanguage)
    }
    
    func cancelLoading() {
        cancelLoadingTask()
    }
    
    // MARK: - Private methods
    
    private func loadChatRoomAvatarIfNeeded(isRightToLeftLanguage: Bool) {
        guard shouldLoadAvatar else { return }
        
        shouldLoadAvatar = false
        loadingChatRoomAvatarTask = Task { [weak self] in
            guard let self else { return }
            
            defer { cancelLoadingTask() }
            
            do {
                try await fetchAvatar(isRightToLeftLanguage: isRightToLeftLanguage)
            } catch {
                shouldLoadAvatar = true
                subscriptions.removeAll()
                MEGALogDebug("Unable to fetch avatar for \(chatRoomEntity.chatId) - \(error.localizedDescription)")
            }
        }
    }
    
    private func cancelLoadingTask() {
        loadingChatRoomAvatarTask?.cancel()
        loadingChatRoomAvatarTask = nil
    }
    
    private func subscribeToAvatarUpdateNotification(forHandles handles: [HandleEntity]) {
        subscriptions.removeAll()
        
        userImageUseCase
            .requestAvatarChangeNotification(forUserHandles: handles)
            .sink { [weak self] _ in
                guard let self, let isRightToLeftLanguage = self.isRightToLeftLanguage else { return }
                
                Task {
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
        if chatRoomEntity.chatType != .oneToOne {
            if let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatRoomEntity.chatId) {
                if chatRoom.peerCount == 0 {
                    guard let emptyGroupAvatar = createAvatar(usingName: title, isRightToLeftLanguage: isRightToLeftLanguage) else { return }
                    
                    await updatePrimaryAvatar(emptyGroupAvatar)
                } else {
                    let primaryAvatarUserHandle = chatRoom.peers[0].handle
                    
                    if chatRoom.peers.count == 1 {
                        let primaryAvatar = try await createAvatar(withHandle: primaryAvatarUserHandle,
                                                                   isRightToLeftLanguage: isRightToLeftLanguage)
                        await updatePrimaryAvatar(primaryAvatar)
                        subscribeToAvatarUpdateNotification(forHandles: [primaryAvatarUserHandle])
                    } else {
                        let secondaryAvatarUserHandle = chatRoom.peers[1].handle
                        let primaryDefaultAvatar = try await createAvatar(withHandle: primaryAvatarUserHandle,
                                                                   isRightToLeftLanguage: isRightToLeftLanguage)
                        let secondaryDefaultAvatar = try await createAvatar(withHandle: secondaryAvatarUserHandle,
                                                                     isRightToLeftLanguage: isRightToLeftLanguage)

                        await updatePrimaryAvatar(primaryDefaultAvatar)
                        await updateSecondaryAvatar(secondaryDefaultAvatar)
                        
                        subscribeToAvatarUpdateNotification(forHandles: [primaryAvatarUserHandle, secondaryAvatarUserHandle])
                        
                        let secondaryAvatar = try await userAvatar(forHandle: secondaryAvatarUserHandle, forceDownload: forceDownload)
                        await updateSecondaryAvatar(secondaryAvatar)
                    }
                    
                    let primaryAvatar = try await userAvatar(forHandle: primaryAvatarUserHandle, forceDownload: forceDownload)
                    await updatePrimaryAvatar(primaryAvatar)
                }
            }
        } else {
            if let avatar = try await createAvatar(withHandle: peerHandle, isRightToLeftLanguage: isRightToLeftLanguage) {
                await updatePrimaryAvatar(avatar)
            }
            
            subscribeToAvatarUpdateNotification(forHandles: [peerHandle])
            
            let oneToOneAvatar = try await userAvatar(forHandle: peerHandle, forceDownload: forceDownload)
            await updatePrimaryAvatar(oneToOneAvatar)
        }
    }
    
    private func createAvatar(withHandle handle: HandleEntity, isRightToLeftLanguage: Bool) async throws -> UIImage? {
        let chatTitle = try await username(forUserHandle: handle, shouldUseMeText: false) ?? title
        
        guard let base64Handle = megaHandleUseCase.base64Handle(forUserHandle: handle),
              let avatarBackgroundHexColor = userImageUseCase.avatarColorHex(forBase64UserHandle: base64Handle)else {
            return nil
        }
        
        return try await userImageUseCase.createAvatar(withUserHandle: peerHandle,
                                                       base64Handle: base64Handle,
                                                       avatarBackgroundHexColor: avatarBackgroundHexColor,
                                                       backgroundGradientHexColor: nil,
                                                       name: chatTitle,
                                                       isRightToLeftLanguage: isRightToLeftLanguage,
                                                       shouldCache: false,
                                                       useCache: false)
    }
    
    private func createAvatar(usingName name: String, isRightToLeftLanguage: Bool, size: CGSize = CGSize(width: 100, height: 100)) -> UIImage? {
        let initials = name
            .components(separatedBy: " ")
            .prefix(2)
            .compactMap({ $0.count > 1 ? String($0.prefix(1)).uppercased() : nil })
            .joined(separator: "")
        
        return UIImage.drawImage(
            forInitials: initials,
            size: size,
            backgroundColor: Colors.Chat.Avatar.background.color,
            backgroundGradientColor: UIColor.mnz_grayDBDBDB(),
            textColor: .white,
            font: UIFont.systemFont(ofSize: min(size.width, size.height)/2.0),
            isRightToLeftLanguage: isRightToLeftLanguage)
    }
    
    private func userAvatar(forHandle handle: HandleEntity, forceDownload: Bool = false) async throws -> UIImage {
        guard let base64Handle = megaHandleUseCase.base64Handle(forUserHandle: handle) else {
            throw UserImageLoadErrorEntity.base64EncodingError
        }
        
        return try await userImageUseCase.fetchAvatar(withUserHandle: handle, base64Handle: base64Handle, forceDownload: forceDownload)
    }
    
    private func username(forUserHandle userHandle: HandleEntity, shouldUseMeText: Bool) async throws -> String? {
        if userHandle == accountUseCase.currentUserHandle {
            return shouldUseMeText ? Strings.Localizable.me : chatUseCase.myFullName()
        } else {
            let usernames = try await chatRoomUserUseCase.userDisplayNames(forPeerIds: [userHandle], in: chatRoomEntity)
            return usernames.first
        }
    }
    
    @MainActor
    private func updatePrimaryAvatar(_ avatar: UIImage?) {
        guard let image = avatar else { return }
        
        primaryAvatar = image
    }
    
    @MainActor
    private func updateSecondaryAvatar(_ avatar: UIImage?) {
        guard let image = avatar else { return }
        
        secondaryAvatar = image
    }
}
