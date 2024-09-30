import MEGADesignToken
import MEGAPresentation
import SwiftUI

final class BottomSheetRouter<Content>: Routing where Content: View {
    private let presenter: UIViewController
    private let content: Content
    
    init(presenter: UIViewController, content: Content) {
        self.presenter = presenter
        self.content = content
    }
    
    func build() -> UIViewController {
        let hostingController = UIHostingController(rootView: content)
        hostingController.modalPresentationStyle = .pageSheet
        if #available(iOS 16.0, *) {
            hostingController.sheetPresentationController?.detents = [
                .custom { context in
                    return context.maximumDetentValue * 0.5
                }
            ]
            hostingController.sheetPresentationController?.detents = [.medium()]
        } else {
            hostingController.sheetPresentationController?.detents = [.medium()]
        }
        hostingController.sheetPresentationController?.prefersGrabberVisible = false
        hostingController.view.backgroundColor = TokenColors.Background.page
        
        return hostingController
    }
    
    func start() {
        presenter.present(build(), animated: true, completion: nil)
    }
}
