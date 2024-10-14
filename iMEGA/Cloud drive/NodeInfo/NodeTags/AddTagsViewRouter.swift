import MEGAPresentation
import SwiftUI

protocol AddTagsViewRouting: Routing {}

@MainActor
struct AddTagsViewRouter: AddTagsViewRouting {
    private let presenter: UIViewController
    
    init(presenter: UIViewController) {
        self.presenter = presenter
    }
    
    func start() {
        presenter.present(build(), animated: true)
    }
    
    func build() -> UIViewController {
        // `doneButtonDisabled` will be handled in [SAO-1819]
        let navigationBarViewModel = AddTagsView.AddTagsViewNavigationBarViewModel(doneButtonDisabled: .constant(true))
        let view = AddTagsView(navigationBarViewModel: navigationBarViewModel)
        return UIHostingController(rootView: view)
    }
}
