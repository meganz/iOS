import MEGADomain
import Combine

final class ChatRoomAvatarViewModel: ObservableObject {
    let title: String
    let peerHandle: HandleEntity
    let chatRoomEntity: ChatRoomEntity
    private let chatRoomUseCase: ChatRoomUseCaseProtocol
    private var userImageUseCase: UserImageUseCaseProtocol
    private let chatUseCase: ChatUseCaseProtocol
    private let accountUseCase: AccountUseCaseProtocol
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
        userImageUseCase: UserImageUseCaseProtocol,
        chatUseCase: ChatUseCaseProtocol,
        accountUseCase: AccountUseCaseProtocol
    ) {
        self.title = title
        self.peerHandle = peerHandle
        self.chatRoomEntity = chatRoomEntity
        self.chatRoomUseCase = chatRoomUseCase
        self.userImageUseCase = userImageUseCase
        self.chatUseCase = chatUseCase
        self.accountUseCase = accountUseCase
    }

    //MARK: - Interface methods
    
    func loadData(isRightToLeftLanguage: Bool) {
        self.isRightToLeftLanguage = isRightToLeftLanguage
        
        guard self.loadingChatRoomAvatarTask == nil else { return }
        self.loadingChatRoomAvatarTask = self.createLoadingChatRoomAvatarTask(isRightToLeftLanguage: isRightToLeftLanguage)
    }
    
    //MARK: - Private methods
    
    private func createLoadingChatRoomAvatarTask(isRightToLeftLanguage: Bool) -> Task<Void, Never> {
        Task { [weak self] in
            let chatId = chatRoomEntity.chatId
            do {
                try await self?.fetchAvatar(isRightToLeftLanguage: isRightToLeftLanguage)
            } catch {
                MEGALogDebug("Unable to fetch avatar for \(chatId) - \(error.localizedDescription)")
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
                    if let avatar = createAvatar(usingName: title, isRightToLeftLanguage: isRightToLeftLanguage) {
                        await updatePrimaryAvatar(avatar)
                    }
                } else {
                    if let primaryAvatarUserHandle = chatRoom.peers.first?.handle,
                        let primaryAvatar = try await createAvatar(
                            withHandle: primaryAvatarUserHandle,
                            isRightToLeftLanguage: isRightToLeftLanguage
                        ) {
                        await updatePrimaryAvatar(primaryAvatar)

                        try Task.checkCancellation()

                        if chatRoom.peers.count > 1,
                           case let secondaryAvatarUserHandle = chatRoom.peers[1].handle,
                            let secondaryAvatar = try await createAvatar(
                                withHandle: secondaryAvatarUserHandle,
                                isRightToLeftLanguage: isRightToLeftLanguage
                            ) {
                            subscribeToAvatarUpdateNotification(forHandles: [primaryAvatarUserHandle, secondaryAvatarUserHandle])
                            await updateSecondaryAvatar(secondaryAvatar)
                            
                            try Task.checkCancellation()

                            do {
                                let downloadedSecondaryAvatar = try await downloadAvatar(forHandle: secondaryAvatarUserHandle)
                                await updateSecondaryAvatar(downloadedSecondaryAvatar)
                            } catch {
                                MEGALogDebug("No avatar to download for \(secondaryAvatarUserHandle)")
                            }
                        } else {
                            subscribeToAvatarUpdateNotification(forHandles: [primaryAvatarUserHandle])
                        }
                        
                        try Task.checkCancellation()
                        
                        do {
                            let downloadedPrimaryAvatar = try await downloadAvatar(forHandle: primaryAvatarUserHandle)
                            await updatePrimaryAvatar(downloadedPrimaryAvatar)
                        } catch {
                            MEGALogDebug("No avatar to download for \(primaryAvatarUserHandle)")
                        }
                    }
                }
            }
        } else {
            if let avatar = try await createAvatar(withHandle: peerHandle, isRightToLeftLanguage: isRightToLeftLanguage) {
                await updatePrimaryAvatar(avatar)
            }
            
            subscribeToAvatarUpdateNotification(forHandles: [peerHandle])
            try Task.checkCancellation()

            let downloadedAvatar = try await downloadAvatar(forHandle: peerHandle)
            await updatePrimaryAvatar(downloadedAvatar)
        }
    }
    
    private func createAvatar(withHandle handle: HandleEntity, isRightToLeftLanguage: Bool) async throws -> UIImage? {
        let chatTitle = try await username(forUserHandle: handle, shouldUseMeText: false) ?? title
        
        guard let base64Handle = MEGASdk.base64Handle(forUserHandle: handle),
              let avatarBackgroundHexColor = MEGASdk.avatarColor(forBase64UserHandle: base64Handle) else {
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
        guard let base64Handle = MEGASdk.base64Handle(forUserHandle: handle) else {
            throw UserImageLoadErrorEntity.base64EncodingError
        }
        
        return try await userImageUseCase.downloadAvatar(withUserHandle: handle, base64Handle: base64Handle)
    }
    
    private func username(forUserHandle userHandle: HandleEntity, shouldUseMeText: Bool) async throws -> String? {
        if userHandle == accountUseCase.currentUser?.handle {
            return shouldUseMeText ? Strings.Localizable.me : chatUseCase.myFullName()
        } else {
            let usernames = try await chatRoomUseCase.userDisplayNames(forPeerIds: [userHandle], chatRoom: chatRoomEntity)
            return usernames.first
        }
    }
    
    @MainActor
    private func updatePrimaryAvatar(_ avatar: UIImage) {
        primaryAvatar = avatar
    }
    
    @MainActor
    private func updateSecondaryAvatar(_ avatar: UIImage) {
        secondaryAvatar = avatar
    }
}
