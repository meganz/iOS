@testable import MEGA
import MEGASwift

final class MockNodeSensitivityChecker: NodeSensitivityChecking, @unchecked Sendable {
    enum Action {
        case evaluateNodeSensitivity(source: NodeSource, displayMode: DisplayMode, isFromSharedItem: Bool)
    }

    @Atomic var actions: [Action] = []
    private let isSensitive: Bool?

    init(isSensitive: Bool? = nil) {
        self.isSensitive = isSensitive
    }

    func evaluateNodeSensitivity(
        for nodeSource: NodeSource,
        displayMode: DisplayMode,
        isFromSharedItem: Bool
    ) async -> Bool? {
        $actions.mutate {
            $0.append(
                .evaluateNodeSensitivity(
                    source: nodeSource,
                    displayMode: displayMode,
                    isFromSharedItem: isFromSharedItem
                )
            )
        }
        return isSensitive
    }
}
