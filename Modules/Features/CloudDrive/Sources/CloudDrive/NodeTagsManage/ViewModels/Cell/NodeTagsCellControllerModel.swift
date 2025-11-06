import Foundation
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADomain
import MEGAL10n

@MainActor
public final class NodeTagsCellControllerModel {
    private let accountUseCase: any AccountUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    let node: NodeEntity
    private let tracker: any AnalyticsTracking
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
        nodeUseCase: some NodeUseCaseProtocol,
        tracker: some AnalyticsTracking = DIContainer.tracker
    ) {
        self.node = node
        self.accountUseCase = accountUseCase
        self.nodeUseCase = nodeUseCase
        self.tracker = tracker
    }

    func trackNodeTagsEntered() {
        tracker.trackAnalyticsEvent(with: NodeInfoTagsEnteredEvent())
    }
}
