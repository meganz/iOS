import Foundation
import MEGADomain

@MainActor
public final class NodeTagsCellControllerModel {
    private let accountUseCase: any AccountUseCaseProtocol
    private let node: NodeEntity
    private(set) lazy var cellViewModel = NodeTagsCellViewModel(
        node: node,
        accountUseCase: accountUseCase,
        notificationCenter: .default
    )

    var hasValidSubscription: Bool {
        accountUseCase.hasValidSubscription
    }
    
    var currentAccountDetails: AccountDetailsEntity? {
        accountUseCase.currentAccountDetails
    }

    var selectedTags: Set<String> {
        Set(node.tags)
    }

    public init(node: NodeEntity, accountUseCase: some AccountUseCaseProtocol) {
        self.node = node
        self.accountUseCase = accountUseCase
    }
}
