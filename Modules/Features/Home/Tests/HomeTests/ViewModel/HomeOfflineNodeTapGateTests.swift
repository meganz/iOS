@testable import Home
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGASwiftUI
import Testing

@Suite("HomeOfflineNodeTapGate Tests")
@MainActor
struct HomeOfflineNodeTapGateTests {

    @Test("reports a file with no local copy with the not-available-offline message")
    func reportsBlockedFile() async {
        let harness = Harness(shouldBlock: true)

        harness.handleTapOnFile()

        let snackBar = await harness.waitForSnackBar()
        #expect(snackBar?.message == Strings.Localizable.CloudDrive.Offline.fileNotAvailableOffline)
        #expect(harness.wrapped.selections.isEmpty, "a blocked tap must not reach the screen's handler")
    }

    @Test("leaves a tap it does not block to the screen's own handler")
    func forwardsAllowedFile() async {
        let harness = Harness(shouldBlock: false)

        harness.handleTapOnFile()

        await harness.waitUntil { !harness.wrapped.selections.isEmpty }
        #expect(harness.sut.snackBar == nil)
    }

    /// The point of a gate per screen: it reports to its own snack bar, wired the moment it is
    /// built, so nothing has to reach it once the view is on screen.
    @Test("is wired to its own snack bar from construction, before any view exists")
    func wiresItselfAtConstruction() async {
        let harness = Harness(shouldBlock: true)

        harness.dispatcher.showFileUnavailableSnackBar()

        #expect(harness.sut.snackBar != nil)
    }

    @Test("does not report a tap while the guard is inactive")
    func inactiveGuardReportsNothing() {
        let harness = Harness(isActive: false, shouldBlock: true)

        harness.handleTapOnFile()

        #expect(harness.wrapped.selections.count == 1)
        #expect(harness.sut.snackBar == nil)
    }
}

// MARK: - Harness

@MainActor
private struct Harness {
    let sut: HomeOfflineNodeTapGate
    let dispatcher: OfflineAwareNodeTapDispatcher
    let wrapped = SpyNodeSelectionHandler()

    init(isActive: Bool = true, shouldBlock: Bool = false) {
        dispatcher = OfflineAwareNodeTapDispatcher(
            offlineFileOpenGuard: MockOfflineFileOpenGuard(isActive: isActive, shouldBlock: shouldBlock),
            nodeUseCase: MockNodeDataUseCase(nodes: [NodeEntity(name: "report.pdf", handle: 1, isFile: true)])
        )
        sut = HomeOfflineNodeTapGate(dispatcher: dispatcher)
    }

    func handleTapOnFile() {
        sut.handler(wrapping: wrapped).handle(selection: NodeSelection(handle: 1, siblings: [2, 3]))
    }

    @discardableResult
    func waitForSnackBar() async -> SnackBar? {
        await waitUntil { sut.snackBar != nil }
        return sut.snackBar
    }

    /// Yields the main actor until the guard's asynchronous check has run. Bounded, so a regression
    /// fails on the assertion that follows instead of hanging the suite.
    func waitUntil(iterations: Int = 1_000, _ condition: () -> Bool) async {
        for _ in 0..<iterations {
            if condition() { return }
            await Task.yield()
        }
    }
}

@MainActor
private final class SpyNodeSelectionHandler: NodeSelectionHandling {
    private(set) var selections: [NodeSelection] = []

    func handle(selection: NodeSelection) {
        selections.append(selection)
    }
}
