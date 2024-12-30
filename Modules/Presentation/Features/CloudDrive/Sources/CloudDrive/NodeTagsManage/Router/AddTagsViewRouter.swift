import MEGADomain
import MEGAPresentation
import MEGASDKRepo
import SwiftUI

protocol AddTagsViewRouting: Routing {}

@MainActor
struct AddTagsViewRouter: AddTagsViewRouting {
    private let nodeEntity: NodeEntity
    private let presenter: UIViewController
    private let isSelectionEnabled = true

    private var selectedTagViewModels: [NodeTagViewModel] {
        nodeEntity.tags.map {
            NodeTagViewModel(tag: $0, isSelected: true)
        }
    }

    init(nodeEntity: NodeEntity, presenter: UIViewController) {
        self.nodeEntity = nodeEntity
        self.presenter = presenter
    }
    
    func start() {
        presenter.present(build(), animated: true)
    }
    
    func build() -> UIViewController {
        let view = ManageTagsView(
            viewModel: ManageTagsViewModel(
                nodeEntity: nodeEntity,
                navigationBarViewModel: ManageTagsViewNavigationBarViewModel(doneButtonDisabled: .constant(true)),
                existingTagsViewModel: ExistingTagsViewModel(
                    nodeEntity: nodeEntity,
                    tagsViewModel: NodeTagsViewModel(
                        tagViewModels: selectedTagViewModels,
                        isSelectionEnabled: isSelectionEnabled
                    ),
                    nodeTagsUseCase: NodeTagsUseCase(
                        repository: NodeTagsRepository.newRepo
                    )
                ),
                tagsUpdatesUseCase: NodeTagsUpdatesUseCase(
                    nodeRepository: NodeRepository.newRepo,
                    nodeTagsRepository: NodeTagsRepository.newRepo
                )
            )
        )
        return UIHostingController(rootView: view)
    }
}
