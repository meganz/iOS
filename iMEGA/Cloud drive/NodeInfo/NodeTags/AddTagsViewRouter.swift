import MEGADomain
import MEGAPresentation
import MEGASDKRepo
import SwiftUI

protocol AddTagsViewRouting: Routing {}

@MainActor
struct AddTagsViewRouter: AddTagsViewRouting {
    private let presenter: UIViewController
    private let isSelectionEnabled = true

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
                existingTagsViewModel: ExistingTagsViewModel(
                    tagsViewModel: NodeTagsViewModel(tagViewModels: []),
                    nodeTagSearcher: NodeTagsSearcher(
                        nodeTagsUseCase: NodeTagsUseCase(
                            repository: NodeTagsRepository()
                        )
                    ),
                    isSelectionEnabled: isSelectionEnabled
                )
            )
        )
        return UIHostingController(rootView: view)
    }
}
