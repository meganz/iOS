@testable import Home
import Testing

@Suite("DoMoreWithMegaActionHandler")
@MainActor
struct DoMoreWithMegaActionHandlerTests {
    @Test("Scan doc starts the add menu document scan")
    func scanDocStartsDocumentScan() {
        let addMenuActionHandler = SpyHomeAddMenuActionHandler()
        let sut = DoMoreWithMegaActionHandler(addMenuActionHandler: addMenuActionHandler)

        sut.handleAction(.scanDoc)

        #expect(addMenuActionHandler.actions == [.scanDocument])
    }
}

private final class SpyHomeAddMenuActionHandler: HomeAddMenuActionHandling {
    private(set) var actions: [HomeAddMenuAction] = []

    func handleAction(_ action: HomeAddMenuAction) {
        actions.append(action)
    }
}
