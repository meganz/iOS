import Foundation
import MEGADomain

@MainActor
final class NodeTagsCellViewModel {
    private let accountUseCase: any AccountUseCaseProtocol
    private let node: NodeEntity

    // Pro only tag is shown to free user only.
    // Please note: It is not shown to user with expired business or expired pro flexi plan.
    var shouldShowProTag: Bool { accountUseCase.isFreeTierUser }
    // Checks if the user has non expired subscription.
    var hasValidSubscription: Bool { accountUseCase.hasValidSubscription }
    var tags: [String] { nodeTagsViewModel.tags }

    private(set) lazy var nodeTagsViewModel = {
        NodeTagsViewModel(tags: node.tags.map { "#" + $0 })
    }()

    init(node: NodeEntity, accountUseCase: some AccountUseCaseProtocol) {
        self.node = node
        self.accountUseCase = accountUseCase
    }
}
