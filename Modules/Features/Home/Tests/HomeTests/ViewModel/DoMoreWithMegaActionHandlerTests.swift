@testable import Home
import MEGADomainMock
import Testing

@Suite("DoMoreWithMegaActionHandler")
@MainActor
struct DoMoreWithMegaActionHandlerTests {
    @Test("Scan doc starts the add menu document scan")
    func scanDocStartsDocumentScan() {
        let addMenuActionHandler = SpyHomeAddMenuActionHandler()
        let sut = makeSUT(addMenuActionHandler: addMenuActionHandler)

        sut.handle(.scanDoc)

        #expect(addMenuActionHandler.actions == [.scanDocument])
    }

    @Test("Add contacts routes to inviteContacts")
    func addContactsRoutesToInviteContacts() throws {
        let router = SpyHomeViewRouter()
        let sut = makeSUT(router: router)

        sut.handle(.addContacts)

        let route = try #require(router.routes.first)
        guard case .inviteContacts = route else {
            Issue.record("Expected inviteContacts, got \(route)")
            return
        }
    }

    @Test("Schedule meeting routes to scheduleMeeting")
    func scheduleMeetingRoutesToScheduleMeeting() throws {
        let router = SpyHomeViewRouter()
        let sut = makeSUT(router: router)

        sut.handle(.scheduleMeeting)

        let route = try #require(router.routes.first)
        guard case .scheduleMeeting = route else {
            Issue.record("Expected scheduleMeeting, got \(route)")
            return
        }
    }

    @Test("Over disk quota routes to the over quota screen")
    func overDiskQuotaRoutesToOverQuota() {
        let router = SpyHomeViewRouter()
        let sut = makeSUT(router: router)

        sut.handle(.overDiskQuota)

        #expect(router.isOverDiskQuotaRouted)
    }

    @Test("Album routes to the album")
    func albumRoutesToAlbum() {
        let router = SpyHomeViewRouter()
        let sut = makeSUT(router: router)

        sut.handle(.album(MockAlbumListUseCase.sampleUserAlbum(name: "Trip")))

        #expect(router.openedAlbumNames == ["Trip"])
    }

    // MARK: - Helpers

    private func makeSUT(
        addMenuActionHandler: SpyHomeAddMenuActionHandler = SpyHomeAddMenuActionHandler(),
        router: SpyHomeViewRouter = SpyHomeViewRouter()
    ) -> DoMoreWithMegaActionHandler {
        DoMoreWithMegaActionHandler(router: router, addMenuActionHandler: addMenuActionHandler)
    }
}

private final class SpyHomeAddMenuActionHandler: HomeAddMenuActionHandling {
    private(set) var actions: [HomeAddMenuAction] = []

    func handleAction(_ action: HomeAddMenuAction) {
        actions.append(action)
    }
}
