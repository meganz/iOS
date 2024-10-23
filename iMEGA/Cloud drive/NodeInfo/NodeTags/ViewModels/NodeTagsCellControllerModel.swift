import Foundation
import MEGADomain

@MainActor
final class NodeTagsCellControllerModel {
    private let accountUseCase: any AccountUseCaseProtocol
    private let node: NodeEntity
    private(set) lazy var cellViewModel = NodeTagsCellViewModel(
        node: node,
        accountUseCase: accountUseCase
    )

    var hasValidSubscription: Bool {
        accountUseCase.hasValidSubscription
    }
    
    var currentAccountDetails: AccountDetailsEntity? {
        accountUseCase.currentAccountDetails
    }

    init(node: NodeEntity, accountUseCase: some AccountUseCaseProtocol) {
        self.node = node
        self.accountUseCase = accountUseCase
    }
}
