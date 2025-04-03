import ChatRepo
import MEGAAppPresentation
import MEGADomain
import SwiftUI
import UIKit

public protocol NoteToSelfChatInfoViewRouterProtocol: Routing {
    func navigateToSharedFiles()
    func navigateToManageChatHistory()
    func navigateToChatsListAfterArchiveNoteToSelfChat()
}

public final class NoteToSelfChatInfoViewRouter: NoteToSelfChatInfoViewRouterProtocol {
    private weak var navigationController: UINavigationController?
    private weak var baseViewController: UIViewController?

    private let chatRoom: ChatRoomEntity
    private let navigateToSharedFilesAction: () -> Void
    private let navigateToManageChatHistoryAction: () -> Void

    public init(
        navigationController: UINavigationController?,
        chatRoom: ChatRoomEntity,
        navigateToSharedFilesAction: @escaping () -> Void,
        navigateToManageChatHistoryAction: @escaping () -> Void
    ) {
        self.navigationController = navigationController
        self.chatRoom = chatRoom
        self.navigateToSharedFilesAction = navigateToSharedFilesAction
        self.navigateToManageChatHistoryAction = navigateToManageChatHistoryAction
    }
    
    public func navigateToSharedFiles() {
        navigateToSharedFilesAction()
    }
    
    public func navigateToManageChatHistory() {
        navigateToManageChatHistoryAction()
    }
    
    public func navigateToChatsListAfterArchiveNoteToSelfChat() {
        navigationController?.popToRootViewController(animated: true)
    }
    
    public func build() -> UIViewController {
        let viewModel = NoteToSelfChatInfoViewModel(
            router: self,
            chatRoomUseCase: ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.newRepo),
            chatRoom: chatRoom
        )
        let hostingVC = UIHostingController(
            rootView: NoteToSelfChatInfoView(viewModel: viewModel)
        )
        baseViewController = hostingVC
        return hostingVC
    }
    
    public func start() {
        navigationController?.pushViewController(build(), animated: true)
    }
}
