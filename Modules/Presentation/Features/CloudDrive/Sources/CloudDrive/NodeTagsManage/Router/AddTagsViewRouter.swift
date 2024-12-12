import MEGADomain
import MEGAPresentation
import MEGASDKRepo
import SwiftUI

protocol AddTagsViewRouting: Routing {}

@MainActor
struct AddTagsViewRouter: AddTagsViewRouting {
    private let presenter: UIViewController
    private let isSelectionEnabled = true
    private let selectedTags: Set<String>

    private var selectedTagViewModels: [NodeTagViewModel] {
        selectedTags.map {
            NodeTagViewModel(tag: $0, isSelected: true)
        }
    }

    init(presenter: UIViewController, selectedTags: Set<String>) {
        self.presenter = presenter
        self.selectedTags = selectedTags
    }
    
    func start() {
        presenter.present(build(), animated: true)
    }
    
    func build() -> UIViewController {
        let view = ManageTagsView(
            viewModel: ManageTagsViewModel(
                navigationBarViewModel: ManageTagsViewNavigationBarViewModel(doneButtonDisabled: .constant(true)),
                existingTagsViewModel: ExistingTagsViewModel(
                    tagsViewModel: NodeTagsViewModel(
                        tagViewModels: selectedTagViewModels,
                        isSelectionEnabled: isSelectionEnabled
                    ),
                    nodeTagSearcher: NodeTagsSearcher(
                        nodeTagsUseCase: NodeTagsUseCase(
                            repository: NodeTagsRepository()
                        )
                    )
                )
            )
        )
        return UIHostingController(rootView: view)
    }
}
