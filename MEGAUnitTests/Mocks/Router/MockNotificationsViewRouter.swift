@testable import MEGA
import MEGADomain

final class MockNotificationsViewRouter: NotificationsViewRouting {
    private(set) var navigateThroughNodeHierarchy_calledTimes = 0
    private(set) var navigateThroughNodeHierarchyAndPresent_calledTimes = 0
    
    func navigateThroughNodeHierarchy(
        _ nodeHierarchy: [NodeEntity],
        isOwnNode: Bool,
        isInRubbishBin: Bool
    ) {
        navigateThroughNodeHierarchy_calledTimes += 1
    }
    
    func navigateThroughNodeHierarchyAndPresent(_ node: NodeEntity) {
        navigateThroughNodeHierarchyAndPresent_calledTimes += 1
    }
}
