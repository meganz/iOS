import MEGADomain
import Combine

final class ChatRoomAvatarViewModel: ObservableObject {
    let chatListItem: ChatListItemEntity
    private let chatRoomUseCase: ChatRoomUseCaseProtocol
    private var userImageUseCase: UserImageUseCaseProtocol
    private let chatUseCase: ChatUseCaseProtocol
    private let userUseCase: UserUseCaseProtocol
    private var isRightToLeftLanguage: Bool?

    @Published private(set) var primaryAvatar: UIImage?
    @Published private(set) var secondaryAvatar: UIImage?
    
    private var subscriptions = Set<AnyCancellable>()
    private var updateAvatarTask: Task<Void, Never>?
    private var loadingChatRoomAvatarTask: Task<Void, Never>?
    private var loadingAvatarSubscription: AnyCancellable?
    
    private var hasInitiatedFetchingAvatar = false

    init(chatListItem: ChatListItemEntity,
         chatRoomUseCase: ChatRoomUseCaseProtocol,
         userImageUseCase: UserImageUseCaseProtocol,
         chatUseCase: ChatUseCaseProtocol,
         userUseCase: UserUseCaseProtocol) {
        self.chatListItem = chatListItem
        self.chatRoomUseCase = chatRoomUseCase
        self.userImageUseCase = userImageUseCase
        self.chatUseCase = chatUseCase
        self.userUseCase = userUseCase
    }

    //MARK: - Interface methods
    
    func loadData(isRightToLeftLanguage: Bool) {
        self.isRightToLeftLanguage = isRightToLeftLanguage
        
        guard hasInitiatedFetchingAvatar == false else { return }
        
        hasInitiatedFetchingAvatar = true
        let subject = PassthroughSubject<Void, Never>()

        loadingAvatarSubscription = subject
            .debounce(for: .seconds(1.0), scheduler: DispatchQueue.global())
            .sink { [weak self] _ in
                guard let self else { return }
                self.loadingChatRoomAvatarTask = self.createLoadingChatRoomAvatarTask(isRightToLeftLanguage: isRightToLeftLanguage)
            }
        
        subject.send()
    }
    
    //MARK: - Private methods
    
    private func createLoadingChatRoomAvatarTask(isRightToLeftLanguage: Bool) -> Task<Void, Never> {
        Task { [weak self] in
            let chatId = chatListItem.chatId
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
        if chatListItem.group {
            if let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatListItem.chatId) {
                if chatRoom.peerCount == 0 {
                    if let chatTitle = chatListItem.title,
                       let avatar = createAvatar(usingName: chatTitle, isRightToLeftLanguage: isRightToLeftLanguage) {
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
            if let avatar = try await createAvatar(withHandle: chatListItem.peerHandle, isRightToLeftLanguage: isRightToLeftLanguage) {
                await updatePrimaryAvatar(avatar)
            }
            
            subscribeToAvatarUpdateNotification(forHandles: [chatListItem.peerHandle])
            try Task.checkCancellation()

            let downloadedAvatar = try await downloadAvatar(forHandle: chatListItem.peerHandle)
            await updatePrimaryAvatar(downloadedAvatar)
        }
    }
    
    private func createAvatar(withHandle handle: HandleEntity, isRightToLeftLanguage: Bool) async throws -> UIImage? {
        let name = try await username(forUserHandle: handle, shouldUseMeText: false)
        
        guard let base64Handle = MEGASdk.base64Handle(forUserHandle: handle),
              let avatarBackgroundHexColor = MEGASdk.avatarColor(forBase64UserHandle: base64Handle),
              let chatTitle = name ?? chatListItem.title  else {
            return nil
        }
        
        return try await userImageUseCase.createAvatar(withUserHandle: chatListItem.peerHandle,
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
        if userHandle == userUseCase.myHandle {
            return shouldUseMeText ? Strings.Localizable.me : chatUseCase.myFullName()
        } else {
            let usernames = try await chatRoomUseCase.userDisplayNames(forPeerIds: [userHandle], chatId: chatListItem.chatId)
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
