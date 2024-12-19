import Foundation
import MEGADomain
import MEGAL10n

@MainActor
public final class NodeTagsCellControllerModel {
    private let accountUseCase: any AccountUseCaseProtocol
    private let node: NodeEntity
    private(set) lazy var cellViewModel = NodeTagsCellViewModel(node: node, accountUseCase: accountUseCase)

    var selectedTags: Set<String> {
        Set(node.tags)
    }
    
    var isExpiredBusinessOrProFlexiAccount: Bool {
        cellViewModel.isExpiredBusinessOrProFlexiAccount
    }

    public init(node: NodeEntity, accountUseCase: some AccountUseCaseProtocol) {
        self.node = node
        self.accountUseCase = accountUseCase
    }
}
