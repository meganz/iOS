import MEGADomain
import MEGAPreference
import Observation

@Observable @MainActor
final class DoMoreWithMegaWidgetViewModel {
    private(set) var tiles: [DoMoreWithMegaTile] = []

    @ObservationIgnored
    @PreferenceWrapper(key: PreferenceKeyEntity.isCameraUploadsEnabled, defaultValue: false)
    private var isCameraUploadsEnabled: Bool

    @ObservationIgnored private let route: @MainActor (HomeWidgetRouteType) -> Void

    init(
        route: @escaping @MainActor (HomeWidgetRouteType) -> Void,
        preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase(repository: PreferenceRepository.newRepo)
    ) {
        self.route = route
        $isCameraUploadsEnabled.useCase = preferenceUseCase
    }

    func refreshTiles() {
        tiles = DoMoreWithMegaTile.allCases.filter { $0 != .cameraUploads || !isCameraUploadsEnabled }
    }

    func didTap(_ tile: DoMoreWithMegaTile) {
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
        // Handle in IOS-11815
    }

    private func didTapCreateAlbum() {
        // Handle in IOS-11816
    }

    private func didTapAddContacts() {
        // Handle in IOS-11818
    }

    private func didTapScheduleMeeting() {
        // Handle in IOS-11817
    }
}
