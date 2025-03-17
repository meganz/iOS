import Combine
import MEGADesignToken
import MEGADomain
import MEGAL10n

@MainActor
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
        if chatRoom.isNoteToSelf {
            return .one(.noteToSelfBlue)
        } else if let primaryAvatarData = chatListItemAvatar.primaryAvatarData,
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
            MEGALogWarning("[ChatRoomAvatar] Unable to fetch avatar for \(megaHandleUseCase.base64Handle(forUserHandle: chatRoom.chatId) ?? "") - \(error.localizedDescription)")
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
                        MEGALogWarning("[ChatRoomAvatar] Updating Avatar task failed for handles \(userHandles)")
                    }
                }
            }
            .store(in: &subscriptions)
    }
    
    private func fetchAvatar(forceDownload: Bool = false) async throws {
        if chatRoom.chatType != .oneToOne {
            if chatRoom.peerCount == 0 {
                try await createEmptyGroupAvatar()
            } else if chatRoom.peers.count == 1 {
                try await createOnePeerAvatar(forceDownload: forceDownload)
            } else {
                try await createTwoOrMorePeerAvatar(forceDownload: forceDownload)
            }
        } else {
            try await createOneToOneAvatar(forceDownload: forceDownload)
        }
    }
    
    private func createEmptyGroupAvatar() async throws {
        guard let emptyGroupAvatar = createAvatar(usingName: title) else { return }
        try await updateAvatar(primary: emptyGroupAvatar, secondary: nil)
    }
    
    private nonisolated func createOnePeerAvatar(forceDownload: Bool) async throws {
        let primaryUserHandle = chatRoom.peers[0].handle
        
        if let localPrimaryAvatar = try await createAvatar(withHandle: primaryUserHandle) {
            try await updateAvatar(primary: localPrimaryAvatar, secondary: nil)
        }
                
        let primaryAvatar = try await userAvatar(forHandle: primaryUserHandle, forceDownload: forceDownload)
        if let primaryImage = UIImage(contentsOfFile: primaryAvatar) {
            try await updateAvatar(primary: primaryImage, secondary: nil)
        }
    }
    
    private nonisolated func createTwoOrMorePeerAvatar(forceDownload: Bool) async throws {
        let primaryUserHandle = chatRoom.peers[0].handle
        let secondaryUserHandle = chatRoom.peers[1].handle
        
        let primaryDefaultAvatar = try await createAvatar(withHandle: primaryUserHandle)
        let secondaryDefaultAvatar = try await createAvatar(withHandle: secondaryUserHandle)
        try await updateAvatar(primary: primaryDefaultAvatar, secondary: secondaryDefaultAvatar)
                
        let primaryAvatar = try await userAvatar(forHandle: primaryUserHandle, forceDownload: forceDownload)
        let secondaryAvatar = try await userAvatar(forHandle: secondaryUserHandle, forceDownload: forceDownload)
        let primaryImage = UIImage(contentsOfFile: primaryAvatar) ?? primaryDefaultAvatar
        let secondaryImage = UIImage(contentsOfFile: secondaryAvatar) ?? secondaryDefaultAvatar
        try await updateAvatar(primary: primaryImage, secondary: secondaryImage)
    }
    
    private nonisolated func createOneToOneAvatar(forceDownload: Bool) async throws {
        if let defaultAvatar = try await createAvatar(withHandle: peerHandle) {
            try await updateAvatar(primary: defaultAvatar, secondary: nil)
        }
                
        let oneToOneAvatar = try await userAvatar(forHandle: peerHandle, forceDownload: forceDownload)
        if let primaryImage = UIImage(contentsOfFile: oneToOneAvatar) {
            try await updateAvatar(primary: primaryImage, secondary: nil)
        }
    }
        
    func createAvatar(withHandle handle: HandleEntity, size: CGSize = CGSize(width: 100, height: 100)) async throws -> UIImage? {
        let chatTitle = try await username(forUserHandle: handle, shouldUseMeText: false) ?? title
        
        guard let base64Handle = megaHandleUseCase.base64Handle(forUserHandle: handle),
              let avatarBackgroundHexColor = userImageUseCase.avatarColorHex(forBase64UserHandle: base64Handle) else {
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
    
    private func createAvatar(usingName name: String, size: CGSize = CGSize(width: 100, height: 100)) -> UIImage? {
        let initials = ChatRoomAvatarInitialsGenerator.generateInitials(from: name)
        
        return UIImage.drawImage(
            forInitials: initials,
            size: size,
            backgroundColor: UIColor.chatAvatarBackground,
            backgroundGradientColor: UIColor.grayDBDBDB,
            textColor: TokenColors.Text.onColor,
            font: UIFont.systemFont(ofSize: min(size.width, size.height)/2.0),
            isRightToLeftLanguage: isRightToLeftLanguage
        )
    }
    
    private nonisolated func userAvatar(forHandle handle: HandleEntity, forceDownload: Bool = false) async throws -> ImageFilePathEntity {
        guard let base64Handle = megaHandleUseCase.base64Handle(forUserHandle: handle) else {
            throw UserImageLoadErrorEntity.base64EncodingError
        }
        
        return try await userImageUseCase.fetchAvatar(
            base64Handle: base64Handle,
            forceDownload: forceDownload
        )
    }
    
    private nonisolated func username(forUserHandle userHandle: HandleEntity, shouldUseMeText: Bool) async throws -> String? {
        if userHandle == accountUseCase.currentUserHandle {
            return shouldUseMeText ? Strings.Localizable.me : chatUseCase.myFullName()
        } else {
            let usernames = try await chatRoomUserUseCase.userDisplayNames(forPeerIds: [userHandle], in: chatRoom)
            return usernames.first
        }
    }
    
    private func updateAvatar(primary: UIImage?, secondary: UIImage?) async throws {
        try Task.checkCancellation()
        
        let newChatRoomAvatar = ChatListItemAvatarEntity(
            primaryAvatarData: primary?.pngData(),
            secondaryAvatarData: secondary?.pngData()
        )
        chatListItemAvatar = newChatRoomAvatar
        
        await chatListItemCacheUseCase.setAvatar(newChatRoomAvatar, for: chatRoom)
    }
}
