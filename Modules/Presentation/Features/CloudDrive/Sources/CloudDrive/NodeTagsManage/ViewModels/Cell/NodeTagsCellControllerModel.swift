import Foundation
import MEGADomain
import MEGAL10n

@MainActor
public final class NodeTagsCellControllerModel {
    private let accountUseCase: any AccountUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    let node: NodeEntity
    private(set) lazy var cellViewModel = NodeTagsCellViewModel(
        node: node,
        accountUseCase: accountUseCase,
        userInteractionEnabled: hasTagsManagementPermission
    )

    var isExpiredBusinessOrProFlexiAccount: Bool {
        cellViewModel.isExpiredBusinessOrProFlexiAccount
    }

    var hasTagsManagementPermission: Bool {
        nodeUseCase.nodeAccessLevel(nodeHandle: node.handle) == .full
        || nodeUseCase.nodeAccessLevel(nodeHandle: node.handle) == .owner
    }

    public init(
        node: NodeEntity,
        accountUseCase: some AccountUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol
    ) {
        self.node = node
        self.accountUseCase = accountUseCase
        self.nodeUseCase = nodeUseCase
    }
}
