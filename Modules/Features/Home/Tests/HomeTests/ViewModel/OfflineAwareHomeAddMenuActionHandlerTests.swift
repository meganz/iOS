@testable import Home
import MEGAAppPresentation
import MEGAAppPresentationMock
import Testing

@Suite("OfflineAwareHomeAddMenuActionHandler Tests")
@MainActor
struct OfflineAwareHomeAddMenuActionHandlerTests {

    /// Pins the policy itself: the floating + button and the Recents empty state's Upload button
    /// open the same menu, and every action in it either starts an upload, opens a remote link or
    /// creates a chat.
    @Test("every add menu action needs a connection", arguments: HomeAddMenuAction.allCases)
    func everyActionRequiresConnection(action: HomeAddMenuAction) {
        #expect(action.requiresConnection)
    }

    @Test("runs an action the guard allows", arguments: HomeAddMenuAction.allCases)
    func allowedActionIsForwarded(action: HomeAddMenuAction) {
        let harness = Harness(allowsAction: true)

        harness.sut.handleAction(action)

        #expect(harness.wrapped.actions == [action])
    }

    @Test("drops an action the guard blocks, so the prompt is the only thing that happens", arguments: HomeAddMenuAction.allCases)
    func blockedActionIsNotForwarded(action: HomeAddMenuAction) {
        let harness = Harness(allowsAction: false)

        harness.sut.handleAction(action)

        #expect(harness.wrapped.actions.isEmpty)
        #expect(harness.guardSpy.allowsActionRequiringConnectionCallCount == 1)
    }
}

// MARK: - Harness

@MainActor
private struct Harness {
    let sut: OfflineAwareHomeAddMenuActionHandler
    let wrapped = SpyHomeAddMenuActionHandler()
    let guardSpy: MockOfflineActionGuard

    init(allowsAction: Bool) {
        guardSpy = MockOfflineActionGuard(allowsAction: allowsAction)
        sut = OfflineAwareHomeAddMenuActionHandler(wrapping: wrapped, offlineActionGuard: guardSpy)
    }
}

@MainActor
private final class SpyHomeAddMenuActionHandler: HomeAddMenuActionHandling {
    private(set) var actions: [HomeAddMenuAction] = []

    func handleAction(_ action: HomeAddMenuAction) {
        actions.append(action)
    }
}
