import Combine
import MEGADomain
import MEGAL10n

final class ChatRoomAvatarViewModel: ObservableObject {
    private let title: String
    private let peerHandle: HandleEntity
    private let chatRoom: ChatRoomEntity
    private let chatRoomUseCase: any ChatRoomUseCaseProtocol
    private let chatRoomUserUseCase: any ChatRoomUserUseCaseProtocol
    private var userImageUseCase: any UserImageUseCaseProtocol
    private let chatUseCase: any ChatUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private let megaHandleUseCase: any MEGAHandleUseCaseProtocol
    private let chatListItemCacheUseCase: any ChatListItemCacheUseCaseProtocol
    
    private var isAvatarLoaded: Bool = false
    @Published private(set) var chatListItemAvatar: ChatListItemAvatarEntity
    private(set) var isRightToLeftLanguage: Bool = false
    
    enum AvatarType {
        case two(primary: UIImage, secondary: UIImage)
        case one(UIImage)
        case placeHolder(String)
    }
    var avatarType: AvatarType {
        if let primaryAvatarData = chatListItemAvatar.primaryAvatarData,
           let secondaryAvatarData = chatListItemAvatar.secondaryAvatarData,
           let primaryAvatar = UIImage(data: primaryAvatarData),
           let secondaryAvatar = UIImage(data: secondaryAvatarData) {
            return .two(primary: primaryAvatar,
                        secondary: secondaryAvatar)
        } else if let primaryAvatar = chatListItemAvatar.primaryAvatarData,
                  let primaryAvatar = UIImage(data: primaryAvatar) {
            return .one(primaryAvatar)
        } else {
            return .placeHolder("circle.fill")
        }
    }
    
    private var subscriptions = Set<AnyCancellable>()
    
    init(
        title: String,
        peerHandle: HandleEntity,
        chatRoom: ChatRoomEntity,
        chatRoomUseCase: some ChatRoomUseCaseProtocol,
        chatRoomUserUseCase: some ChatRoomUserUseCaseProtocol,
        userImageUseCase: some UserImageUseCaseProtocol,
        chatUseCase: some ChatUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol,
        megaHandleUseCase: some MEGAHandleUseCaseProtocol,
        chatListItemCacheUseCase: some ChatListItemCacheUseCaseProtocol,
        chatListItemAvatar: ChatListItemAvatarEntity? = nil
    ) {
        self.title = title
        self.peerHandle = peerHandle
        self.chatRoom = chatRoom
        self.chatRoomUseCase = chatRoomUseCase
        self.chatRoomUserUseCase = chatRoomUserUseCase
        self.userImageUseCase = userImageUseCase
        self.chatUseCase = chatUseCase
        self.accountUseCase = accountUseCase
        self.megaHandleUseCase = megaHandleUseCase
        self.chatListItemCacheUseCase = chatListItemCacheUseCase
        self.chatListItemAvatar = chatListItemAvatar ?? ChatListItemAvatarEntity(
            primaryAvatarData: nil, secondaryAvatarData: nil
        )
        subscribeToAvatarUpdateNotification()
    }
    
    // MARK: - Interface methods
    
    func loadAvatar(isRightToLeftLanguage: Bool) async {
        guard !isAvatarLoaded else { return }
        self.isRightToLeftLanguage = isRightToLeftLanguage
        do {
            try await fetchAvatar()
            isAvatarLoaded = true
        } catch {
            MEGALogDebug("Unable to fetch avatar for \(chatRoom.chatId) - \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private methods
    
    private func subscribeToAvatarUpdateNotification() {
        let userHandles = chatRoom.chatType != .oneToOne ? Array(chatRoom.peers.map(\.handle).prefix(2)) : [peerHandle]
        guard userHandles.count > 0 else { return }
        userImageUseCase
            .requestAvatarChangeNotification(forUserHandles: userHandles)
            .sink { [weak self] _ in
                guard let self else { return }
                Task {
                    do {
                        try await self.fetchAvatar(forceDownload: true)
                    } catch {
                        MEGALogDebug("Updating Avatar task failed for handles \(userHandles)")
                    }
                }
            }
            .store(in: &subscriptions)
    }
    
    private func fetchAvatar(forceDownload: Bool = false) async throws {
        if chatRoom.chatType != .oneToOne {
            if chatRoom.peerCount == 0 {
                await createEmptyGroupAvatar()
            } else if chatRoom.peers.count == 1 {
                try await createOnePeerAvatar(forceDownload: forceDownload)
            } else {
                try await createTwoOrMorePeerAvatar(forceDownload: forceDownload)
            }
        } else {
            try await createOneToOneAvatar(forceDownload: forceDownload)
        }
    }
    
    private func createEmptyGroupAvatar() async {
        guard let emptyGroupAvatar = createAvatar(usingName: title) else { return }
        await updateAvatar(primary: emptyGroupAvatar, secondary: nil)
    }
    
    private func createOnePeerAvatar(forceDownload: Bool) async throws {
        let primaryUserHandle = chatRoom.peers[0].handle
        
        if let localPrimaryAvatar = try await createAvatar(withHandle: primaryUserHandle) {
            await updateAvatar(primary: localPrimaryAvatar, secondary: nil)
        }
                
        let primaryAvatar = try await userAvatar(forHandle: primaryUserHandle, forceDownload: forceDownload)
        await updateAvatar(primary: primaryAvatar, secondary: nil)
    }
    
    private func createTwoOrMorePeerAvatar(forceDownload: Bool) async throws {
        let primaryUserHandle = chatRoom.peers[0].handle
        let secondaryUserHandle = chatRoom.peers[1].handle
        
        if let primaryDefaultAvatar = try await createAvatar(withHandle: primaryUserHandle),
           let secondaryDefaultAvatar = try await createAvatar(withHandle: secondaryUserHandle) {
            await updateAvatar(primary: primaryDefaultAvatar, secondary: secondaryDefaultAvatar)
        }
                
        let primaryAvatar = try await userAvatar(forHandle: primaryUserHandle, forceDownload: forceDownload)
        let secondaryAvatar = try await userAvatar(forHandle: secondaryUserHandle, forceDownload: forceDownload)
        await updateAvatar( primary: primaryAvatar, secondary: secondaryAvatar)
    }
    
    private func createOneToOneAvatar(forceDownload: Bool) async throws {
        if let defaultAvatar = try await createAvatar(withHandle: peerHandle) {
            await updateAvatar(primary: defaultAvatar, secondary: nil)
        }
                
        let oneToOneAvatar = try await userAvatar(forHandle: peerHandle, forceDownload: forceDownload)
        await updateAvatar(primary: oneToOneAvatar, secondary: nil)
    }
        
    private func createAvatar(withHandle handle: HandleEntity) async throws -> UIImage? {
        let chatTitle = try await username(forUserHandle: handle, shouldUseMeText: false) ?? title
        
        guard let base64Handle = megaHandleUseCase.base64Handle(forUserHandle: handle),
              let avatarBackgroundHexColor = userImageUseCase.avatarColorHex(forBase64UserHandle: base64Handle) else {
            return nil
        }
        
        return try await userImageUseCase.createAvatar(
            withUserHandle: peerHandle,
            base64Handle: base64Handle,
            avatarBackgroundHexColor: avatarBackgroundHexColor,
            backgroundGradientHexColor: nil,
            name: chatTitle,
            isRightToLeftLanguage: isRightToLeftLanguage,
            shouldCache: false,
            useCache: false
        )
    }
    
    private func createAvatar(usingName name: String, size: CGSize = CGSize(width: 100, height: 100)) -> UIImage? {
        let initials = ChatRoomAvatarInitialsGenerator.generateInitials(from: name)
        
        return UIImage.drawImage(
            forInitials: initials,
            size: size,
            backgroundColor: Colors.Chat.Avatar.background.color,
            backgroundGradientColor: UIColor.mnz_grayDBDBDB(),
            textColor: .white,
            font: UIFont.systemFont(ofSize: min(size.width, size.height)/2.0),
            isRightToLeftLanguage: isRightToLeftLanguage
        )
    }
    
    private func userAvatar(forHandle handle: HandleEntity, forceDownload: Bool = false) async throws -> UIImage {
        guard let base64Handle = megaHandleUseCase.base64Handle(forUserHandle: handle) else {
            throw UserImageLoadErrorEntity.base64EncodingError
        }
        
        return try await userImageUseCase.fetchAvatar(
            base64Handle: base64Handle,
            forceDownload: forceDownload
        )
    }
    
    private func username(forUserHandle userHandle: HandleEntity, shouldUseMeText: Bool) async throws -> String? {
        if userHandle == accountUseCase.currentUserHandle {
            return shouldUseMeText ? Strings.Localizable.me : chatUseCase.myFullName()
        } else {
            let usernames = try await chatRoomUserUseCase.userDisplayNames(forPeerIds: [userHandle], in: chatRoom)
            return usernames.first
        }
    }
    
    @MainActor 
    private func updateAvatar(primary: UIImage?, secondary: UIImage?) {
        guard !Task.isCancelled else { return }
        
        let newChatRoomAvatar = ChatListItemAvatarEntity(
            primaryAvatarData: primary?.pngData(),
            secondaryAvatarData: secondary?.pngData()
        )
        chatListItemAvatar = newChatRoomAvatar
        Task {
            await chatListItemCacheUseCase.setAvatar(
                newChatRoomAvatar,
                for: chatRoom
            )
        }
    }
}
