import AsyncAlgorithms
import Foundation
import MEGADomain

@MainActor
final class NodeTagsCellViewModel: ObservableObject, Sendable {
    private let node: NodeEntity
    private let isSelectionAvailable: Bool = false
    private let accountUseCase: any AccountUseCaseProtocol

    var tags: [String] { node.tags }

    var isExpiredBusinessOrProFlexiAccount: Bool {
        accountUseCase.hasExpiredBusinessAccount() || accountUseCase.hasExpiredProFlexiAccount()
    }

    let userInteractionEnabled: Bool

    private(set) lazy var nodeTagsViewModel = {
        NodeTagsViewModel(
            tagViewModels: node.tags.map {
                NodeTagViewModel(tag: $0, isSelected: isSelectionAvailable)
            },
            isSelectionEnabled: isSelectionAvailable
        )
    }()

    init(node: NodeEntity, accountUseCase: some AccountUseCaseProtocol, userInteractionEnabled: Bool) {
        self.node = node
        self.accountUseCase = accountUseCase
        self.userInteractionEnabled = userInteractionEnabled
    }
}
