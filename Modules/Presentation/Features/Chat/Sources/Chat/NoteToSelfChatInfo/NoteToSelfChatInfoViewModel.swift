import Combine
import MEGADomain
import MEGAPresentation
import MEGAL10n
import MEGASDKRepo

@MainActor
public final class NoteToSelfChatInfoViewModel: ObservableObject {
    private let router: any NoteToSelfChatInfoViewRouterProtocol
    private let chatRoomUseCase: any ChatRoomUseCaseProtocol
    private var chatRoom: ChatRoomEntity
    
    @Published var isArchived: Bool
    @Published var showArchiveChatAlert: Bool = false
    
    public init(
        router: some NoteToSelfChatInfoViewRouterProtocol,
        chatRoomUseCase: some ChatRoomUseCaseProtocol,
        chatRoom: ChatRoomEntity
    ) {
        self.router = router
        self.chatRoomUseCase = chatRoomUseCase
        self.chatRoom = chatRoom
        self.isArchived = chatRoom.isArchived
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
            }
        } catch {
            MEGALogError("[NoteToSelf Info] Error archiving/unarchiving chat: \(error)")
        }
    }
}
