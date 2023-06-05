import Foundation

final class PasteImagePreviewRouter: PasteImagePreviewRouting {
    private weak var baseViewController: UIViewController?
    private weak var viewControllerToPresent: UIViewController?
    private let chatRoom: MEGAChatRoom

    init(viewControllerToPresent: UIViewController, chatRoom: MEGAChatRoom) {
        self.viewControllerToPresent = viewControllerToPresent
        self.chatRoom = chatRoom
    }
    
    func build() -> UIViewController {
        let vm = PasteImagePreviewViewModel(router: self, chatRoom: chatRoom)
        
        let vc = PasteImagePreviewViewController()
        
        vc.viewModel = vm
        baseViewController = vc
        return vc
    }
    
    func start() {
        guard let viewControllerToPresent = viewControllerToPresent else {
            return
        }
        viewControllerToPresent.present(build(), animated: true, completion: nil)
    }
    
    // MARK: - UI Actions
    func dismiss() {
        baseViewController?.dismiss(animated: true)
    }
    
}
