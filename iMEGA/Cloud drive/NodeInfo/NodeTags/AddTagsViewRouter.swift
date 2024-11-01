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
        let view = ManageTagsView(
            viewModel: ManageTagsViewModel(
                navigationBarViewModel: ManageTagsViewNavigationBarViewModel(doneButtonDisabled: .constant(true)),
                existingTagsViewModel: ExistingTagsViewModel()
            )
        )
        return UIHostingController(rootView: view)
    }
}
