import MEGADomain
import Combine

final class ChatRoomAvatarViewModel: ObservableObject {
    let title: String
    let peerHandle: HandleEntity
    let chatRoomEntity: ChatRoomEntity
    private let chatRoomUseCase: ChatRoomUseCaseProtocol
    private let chatRoomUserUseCase: ChatRoomUserUseCaseProtocol
    private var userImageUseCase: UserImageUseCaseProtocol
    private let chatUseCase: ChatUseCaseProtocol
    private let accountUseCase: AccountUseCaseProtocol
    private let megaHandleUseCase: MEGAHandleUseCaseProtocol
    private var isRightToLeftLanguage: Bool?
    
    @Published private(set) var primaryAvatar: UIImage?
    @Published private(set) var secondaryAvatar: UIImage?
    
    private var subscriptions = Set<AnyCancellable>()
    private var updateAvatarTask: Task<Void, Never>?
    private var loadingChatRoomAvatarTask: Task<Void, Never>?
    private var loadingAvatarSubscription: AnyCancellable?
    
    init(
        title: String,
        peerHandle: HandleEntity,
        chatRoomEntity: ChatRoomEntity,
        chatRoomUseCase: ChatRoomUseCaseProtocol,
        chatRoomUserUseCase: ChatRoomUserUseCaseProtocol,
        userImageUseCase: UserImageUseCaseProtocol,
        chatUseCase: ChatUseCaseProtocol,
        accountUseCase: AccountUseCaseProtocol,
        megaHandleUseCase: MEGAHandleUseCaseProtocol
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
    
    //MARK: - Interface methods
    
    func loadAvatar(isRightToLeftLanguage: Bool) {
        self.isRightToLeftLanguage = isRightToLeftLanguage
        
        loadChatRoomAvatar(isRightToLeftLanguage: isRightToLeftLanguage)
    }
    
    func cancelLoading() {
        loadingChatRoomAvatarTask?.cancel()
        loadingChatRoomAvatarTask = nil
        
        subscriptions.removeAll()
    }
    
    //MARK: - Private methods
    
    private func loadChatRoomAvatar(isRightToLeftLanguage: Bool) {
        loadingChatRoomAvatarTask = Task { [weak self] in
            do {
                try await self?.fetchAvatar(isRightToLeftLanguage: isRightToLeftLanguage)
                
            } catch {
                MEGALogDebug("Unable to fetch avatar for \(chatRoomEntity.chatId) - \(error.localizedDescription)")
            }
        }
    }
    
    private func subscribeToAvatarUpdateNotification(forHandles handles: [HandleEntity]) {
        subscriptions.removeAll()
        
        userImageUseCase
            .requestAvatarChangeNotification(forUserHandles: handles)
            .sink { [weak self] _ in
                guard let self, let isRightToLeftLanguage = self.isRightToLeftLanguage else { return }
                
                self.updateAvatarTask = Task {
                    do {
                        try await self.fetchAvatar(isRightToLeftLanguage: isRightToLeftLanguage)
                    } catch {
                        MEGALogDebug("Updating Avatar task failed for handles \(handles)")
                    }
                }
            }
            .store(in: &subscriptions)
    }
    
    private func fetchAvatar(isRightToLeftLanguage: Bool) async throws {
        if chatRoomEntity.chatType != .oneToOne {
            if let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatRoomEntity.chatId) {
                if chatRoom.peerCount == 0 {
                    guard let avatar = createAvatar(usingName: title, isRightToLeftLanguage: isRightToLeftLanguage) else { return }
                    
                    await updatePrimaryAvatar(avatar)
                } else {
                    let primaryAvatarUserHandle = chatRoom.peers[0].handle
                    
                    if chatRoom.peers.count == 1 {
                        let primaryAvatar = try await createAvatar(withHandle: primaryAvatarUserHandle,
                                                                   isRightToLeftLanguage: isRightToLeftLanguage)
                        await updatePrimaryAvatar(primaryAvatar)
                        subscribeToAvatarUpdateNotification(forHandles: [primaryAvatarUserHandle])
                    } else {
                        let secondaryAvatarUserHandle = chatRoom.peers[1].handle
                        let primaryAvatar = try await createAvatar(withHandle: primaryAvatarUserHandle,
                                                                   isRightToLeftLanguage: isRightToLeftLanguage)
                        let secondaryAvatar = try await createAvatar(withHandle: secondaryAvatarUserHandle,
                                                                     isRightToLeftLanguage: isRightToLeftLanguage)
                        
                        await updatePrimaryAvatar(primaryAvatar)
                        await updateSecondaryAvatar(secondaryAvatar)
                        
                        subscribeToAvatarUpdateNotification(forHandles: [primaryAvatarUserHandle, secondaryAvatarUserHandle])
                        
                        let downloadedSecondaryAvatar = try await downloadAvatar(forHandle: secondaryAvatarUserHandle)
                        await updateSecondaryAvatar(downloadedSecondaryAvatar)
                    }
                    
                    let downloadedPrimaryAvatar = try await downloadAvatar(forHandle: primaryAvatarUserHandle)
                    await updateSecondaryAvatar(downloadedPrimaryAvatar)
                }
            }
        } else {
            if let avatar = try await createAvatar(withHandle: peerHandle, isRightToLeftLanguage: isRightToLeftLanguage) {
                await updatePrimaryAvatar(avatar)
            }
            
            subscribeToAvatarUpdateNotification(forHandles: [peerHandle])
            
            let downloadedAvatar = try await downloadAvatar(forHandle: peerHandle)
            await updatePrimaryAvatar(downloadedAvatar)
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
    
    private func createAvatar(usingName name: String, isRightToLeftLanguage: Bool, size: CGSize = CGSizeMake(100, 100)) -> UIImage?  {
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
    
    private func downloadAvatar(forHandle handle: HandleEntity) async throws -> UIImage {
        guard let base64Handle = megaHandleUseCase.base64Handle(forUserHandle: handle) else {
            throw UserImageLoadErrorEntity.base64EncodingError
        }
        
        return try await userImageUseCase.downloadAvatar(withUserHandle: handle, base64Handle: base64Handle)
    }
    
    private func username(forUserHandle userHandle: HandleEntity, shouldUseMeText: Bool) async throws -> String? {
        if userHandle == accountUseCase.currentUser?.handle {
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
