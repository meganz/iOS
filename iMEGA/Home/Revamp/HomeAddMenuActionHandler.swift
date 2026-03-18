import Home
import UIKit

@MainActor
struct HomeAddMenuActionHandler: HomeAddMenuActionHandling {

    private let uploadAddMenuDelegateHandler: UploadAddMenuDelegateHandler
    private let newChatRouter: NewChatRouter
    private unowned let navigationController: UINavigationController

    init(
        uploadAddMenuDelegateHandler: UploadAddMenuDelegateHandler,
        newChatRouter: NewChatRouter,
        navigationController: UINavigationController
    ) {
        self.uploadAddMenuDelegateHandler = uploadAddMenuDelegateHandler
        self.newChatRouter = newChatRouter
        self.navigationController = navigationController
    }

    func handleAction(_ action: HomeAddMenuAction) {
        switch action {
        case .chooseFromPhotos:
            uploadAddMenuDelegateHandler.uploadAddMenu(didSelect: .chooseFromPhotos)
        case .capture:
            uploadAddMenuDelegateHandler.uploadAddMenu(didSelect: .capture)
        case .importFromFiles:
            uploadAddMenuDelegateHandler.uploadAddMenu(didSelect: .importFrom)
        case .scanDocument:
            uploadAddMenuDelegateHandler.uploadAddMenu(didSelect: .scanDocument)
        case .newTextFile:
            uploadAddMenuDelegateHandler.uploadAddMenu(didSelect: .newTextFile)
        case .newChat:
            newChatRouter.presentNewChat(from: navigationController)
        }
    }
}
