@testable import Home
import Testing

@Suite("DoMoreWithMegaActionHandler")
@MainActor
struct DoMoreWithMegaActionHandlerTests {
    @Test("Add contacts routes to inviteContacts")
    func addContactsRoutesToInviteContacts() throws {
        let router = SpyHomeViewRouter()
        let sut = DoMoreWithMegaActionHandler(router: router, addMenuActionHandler: SpyHomeAddMenuActionHandler())

        sut.handleAction(.addContacts)

        let route = try #require(router.routes.first)
        guard case .inviteContacts = route else {
            Issue.record("Expected inviteContacts, got \(route)")
            return
        }
    }

    @Test("Scan doc starts the add menu document scan")
    func scanDocStartsDocumentScan() {
        let addMenuActionHandler = SpyHomeAddMenuActionHandler()
        let sut = DoMoreWithMegaActionHandler(router: SpyHomeViewRouter(), addMenuActionHandler: addMenuActionHandler)

        sut.handleAction(.scanDoc)

        #expect(addMenuActionHandler.actions == [.scanDocument])
    }

    @Test("Schedule meeting routes to scheduleMeeting")
    func scheduleMeetingRoutesToScheduleMeeting() throws {
        let router = SpyHomeViewRouter()
        let sut = DoMoreWithMegaActionHandler(router: router, addMenuActionHandler: SpyHomeAddMenuActionHandler())

        sut.handleAction(.scheduleMeeting)

        let route = try #require(router.routes.first)
        guard case .scheduleMeeting = route else {
            Issue.record("Expected scheduleMeeting, got \(route)")
            return
        }
    }
}

private final class SpyHomeAddMenuActionHandler: HomeAddMenuActionHandling {
    private(set) var actions: [HomeAddMenuAction] = []

    func handleAction(_ action: HomeAddMenuAction) {
        actions.append(action)
    }
}

private final class SpyHomeViewRouter: HomeViewRouting {
    private(set) var routes: [HomeWidgetRouteType] = []

    func route(to type: HomeWidgetRouteType) {
        routes.append(type)
    }

    func openOfflineFile(base64Handle: String) {}

    func openNode(base64Handle: String) {}
}
