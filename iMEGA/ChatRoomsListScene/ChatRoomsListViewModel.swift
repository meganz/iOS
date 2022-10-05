import Foundation
import MEGADomain
import Combine

enum ChatMode {
    case chats
    case meetings
}

enum ChatType {
    case regular
    case archived
}

protocol ChatRoomsListRouting: Routing {
    func presentStartConversation()
}

final class ChatRoomsListViewModel: ObservableObject {
    private let router: ChatRoomsListRouting
    private let chatUseCase: ChatUseCaseProtocol
    
    private let chatType: ChatType
    
    @Published var chatMode: ChatMode = .chats
    @Published var chatStatus: ChatStatusEntity?
    @Published var title: String = Strings.Localizable.Chat.title

    private var subscriptions = Set<AnyCancellable>()

    init(router: ChatRoomsListRouting,
         chatUseCase: ChatUseCaseProtocol,
         chatType: ChatType = .regular
    ) {
        self.router = router
        self.chatUseCase = chatUseCase
        self.chatType = chatType
        
        configureTitle()
        listeningForChatStatusUpdate()
    }
    
    func listeningForChatStatusUpdate () {
        chatUseCase
            .monitorSelfChatStatusChange()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { error in
                MEGALogDebug("error fetching the changed status \(error)")
            }, receiveValue: { [weak self] status in
                self?.chatStatus = status
            })
            .store(in: &subscriptions)
    }
    
    func selectChatMode(_ mode: ChatMode) {
        guard mode != chatMode else { return }
        chatMode = mode
    }
    
    func addChatButtonTapped() {
        router.presentStartConversation()
    }
    
    func changeChatStatus(to status: ChatStatusEntity) {
        guard status != chatStatus else {
            return
        }
        chatUseCase.changeChatStatus(to: status)
    }
    
    private func configureTitle() {
        switch chatType {
        case .regular:
            title = Strings.Localizable.Chat.title
        case .archived:
            title = Strings.Localizable.archivedChats
        }
    }
}
