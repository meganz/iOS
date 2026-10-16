import MEGADomain

enum DoMoreWithMegaAction: Equatable {
    case cameraUploadsOnboarding
    case cameraUploadsSettings
    case scanDoc
    case addContacts
    case scheduleMeeting
    case overDiskQuota
    case album(AlbumEntity)
}

@MainActor
protocol DoMoreWithMegaActionHandling {
    func handle(_ action: DoMoreWithMegaAction)
}

struct DoMoreWithMegaActionHandler: DoMoreWithMegaActionHandling {
    private let router: any HomeViewRouting
    private let addMenuActionHandler: any HomeAddMenuActionHandling

    init(router: some HomeViewRouting, addMenuActionHandler: some HomeAddMenuActionHandling) {
        self.router = router
        self.addMenuActionHandler = addMenuActionHandler
    }

    func handle(_ action: DoMoreWithMegaAction) {
        switch action {
        case .cameraUploadsOnboarding: router.route(to: .cameraUploadsOnboarding)
        case .cameraUploadsSettings: router.route(to: .cameraUploadsSettings)
        case .scanDoc: didTapScanDoc()
        case .addContacts: didTapAddContacts()
        case .scheduleMeeting: didTapScheduleMeeting()
        case .overDiskQuota: router.route(to: .overDiskQuota)
        case .album(let album): router.route(to: .album(album))
        }
    }

    // MARK: - Tile handlers

    private func didTapScanDoc() {
        addMenuActionHandler.handleAction(.scanDocument)
    }

    private func didTapAddContacts() {
        router.route(to: .inviteContacts)
    }

    private func didTapScheduleMeeting() {
        router.route(to: .scheduleMeeting)
    }
}
