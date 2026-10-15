@MainActor
protocol DoMoreWithMegaActionHandling {
    func handleAction(_ tile: DoMoreWithMegaTile)
}

struct DoMoreWithMegaActionHandler: DoMoreWithMegaActionHandling {
    private let router: any HomeViewRouting
    private let addMenuActionHandler: any HomeAddMenuActionHandling

    init(router: some HomeViewRouting, addMenuActionHandler: some HomeAddMenuActionHandling) {
        self.router = router
        self.addMenuActionHandler = addMenuActionHandler
    }

    func handleAction(_ tile: DoMoreWithMegaTile) {
        switch tile {
        case .cameraUploads: didTapCameraUploads()
        case .scanDoc: didTapScanDoc()
        case .createAlbum: didTapCreateAlbum()
        case .addContacts: didTapAddContacts()
        case .scheduleMeeting: didTapScheduleMeeting()
        }
    }

    // MARK: - Tile handlers

    private func didTapCameraUploads() {
        // Handle in IOS-11814
    }

    private func didTapScanDoc() {
        addMenuActionHandler.handleAction(.scanDocument)
    }

    private func didTapCreateAlbum() {
        // Handle in IOS-11816
    }

    private func didTapAddContacts() {
        router.route(to: .inviteContacts)
    }

    private func didTapScheduleMeeting() {
        // Handle in IOS-11817
    }
}
