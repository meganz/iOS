import Foundation

enum PasteImagePreviewAction: ActionType {
    case didClickSend
    case didClickCancel

}

protocol PasteImagePreviewRouting: Routing {
    func dismiss()

}

final class PasteImagePreviewViewModel: ViewModelType {
    enum Command: CommandType, Equatable {     
    }
    
    // MARK: - Private properties
    private let router: PasteImagePreviewRouting
    private let chatRoom: MEGAChatRoom
    
    // MARK: - Internel properties
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    init(router: PasteImagePreviewRouting, chatRoom: MEGAChatRoom) {
        self.router = router
        self.chatRoom = chatRoom
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: PasteImagePreviewAction) {
        switch action {
        case .didClickCancel:
            router.dismiss()
        case .didClickSend:
            didClickSend()
        }
    }
    
    private func didClickSend() {
        router.dismiss()
        guard let image = UIPasteboard.general.loadImage() else {
            return
        }
        ChatUploader.sharedInstance.upload(image: image, chatRoomId: chatRoom.chatId)
    }
}
