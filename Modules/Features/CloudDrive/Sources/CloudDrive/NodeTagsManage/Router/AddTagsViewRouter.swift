import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import SwiftUI

protocol AddTagsViewRouting: Routing {}

@MainActor
struct AddTagsViewRouter: AddTagsViewRouting {
    private let nodeEntity: NodeEntity
    private let presenter: UIViewController
    private let isSelectionEnabled = true
    private let featureFlagProvider: any FeatureFlagProviderProtocol

    private var selectedTagViewModels: [NodeTagViewModel] {
        nodeEntity.tags.map {
            NodeTagViewModel(tag: $0, isSelected: true)
        }
    }

    init(nodeEntity: NodeEntity, presenter: UIViewController, featureFlagProvider: some FeatureFlagProviderProtocol) {
        self.nodeEntity = nodeEntity
        self.presenter = presenter
        self.featureFlagProvider = featureFlagProvider
    }
    
    func start() {
        presenter.present(build(), animated: true)
    }
    
    func build() -> UIViewController {
        let isLiquidGlassEnabled: Bool = if #available(iOS 26.0, *), featureFlagProvider.isLiquidGlassEnabled() {
            true
        } else {
            false
        }
        let view = ManageTagsView(
            viewModel: ManageTagsViewModel(
                nodeEntity: nodeEntity,
                navigationBarViewModel: ManageTagsViewNavigationBarViewModel(isLiquidGlassEnabled: isLiquidGlassEnabled),
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
                ),
                nodeTagsUseCase: NodeTagsUseCase(repository: NodeTagsRepository.newRepo)
            )
        )
        return UIHostingController(rootView: view)
    }
}
