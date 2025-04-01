import Combine
import MEGAAppPresentation
import MEGADomain
import MEGASDKRepo

@MainActor
public final class NoteToSelfChatInfoViewModel: ObservableObject {
    private let router: any NoteToSelfChatInfoViewRouterProtocol
    private let chatRoomUseCase: any ChatRoomUseCaseProtocol
    private var chatRoom: ChatRoomEntity
    
    @Published var isArchived: Bool
    
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
    
    func archiveChatTapped() async {
        do {
            let archivedValue = try await chatRoomUseCase.archive(!chatRoom.isArchived, chatRoom: chatRoom)
            isArchived = archivedValue
            guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatRoom.chatId) else {
                return
            }
            self.chatRoom = chatRoom
        } catch {
            MEGALogError("[NoteToSelf Info] Error archiving/unarchiving chat: \(error)")
        }
    }
}
