import Combine
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n

@MainActor
public final class NoteToSelfChatInfoViewModel: ObservableObject {
    private let router: any NoteToSelfChatInfoViewRouterProtocol
    private let chatRoomUseCase: any ChatRoomUseCaseProtocol
    private let chatUseCase: any ChatUseCaseProtocol
    private var chatRoom: ChatRoomEntity
    private let tracker: any AnalyticsTracking

    @Published var isArchived: Bool
    @Published var showArchiveChatAlert: Bool = false
    
    public init(
        router: some NoteToSelfChatInfoViewRouterProtocol,
        chatRoomUseCase: some ChatRoomUseCaseProtocol,
        chatUseCase: some ChatUseCaseProtocol,
        chatRoom: ChatRoomEntity,
        tracker: some AnalyticsTracking = DIContainer.tracker
    ) {
        self.router = router
        self.chatRoomUseCase = chatRoomUseCase
        self.chatUseCase = chatUseCase
        self.chatRoom = chatRoom
        self.isArchived = chatRoom.isArchived
        self.tracker = tracker
    }
    
    func filesRowTapped() {
        router.navigateToSharedFiles()
    }
    
    func manageChatHistoryTapped() {
        router.navigateToManageChatHistory()
    }
    
    func archiveChatTapped() {
        showArchiveChatAlert = true
    }
    
    func cancelArchiveChat() {
        showArchiveChatAlert = false
    }
    
    var archiveChatAlertTitle: String {
        chatRoom.isArchived ? Strings.Localizable.unarchiveChatMessage : Strings.Localizable.archiveChatMessage
    }
        
    func archiveChat() async {
        showArchiveChatAlert = false
        do {
            let archivedValue = try await chatRoomUseCase.archive(!chatRoom.isArchived, chatRoom: chatRoom)
            isArchived = archivedValue
            guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatRoom.chatId) else {
                return
            }
            self.chatRoom = chatRoom
            if chatRoom.isArchived {
                router.navigateToChatsListAfterArchiveNoteToSelfChat()
                tracker.trackAnalyticsEvent(with: ArchiveNoteToSelfButtonPressedEvent())
            }
        } catch {
            MEGALogError("[NoteToSelf Info] Error archiving/unarchiving chat: \(error)")
        }
    }
    
    var isNoteToSelfChatAndEmpty: Bool {
        guard let chatListItem = chatUseCase.chatListItem(forChatId: chatRoom.chatId) else { return false }
        return chatListItem.lastMessageId == .invalid
    }
}
