import MEGADomain
import MEGAPreference
import Observation

@Observable @MainActor
final class DoMoreWithMegaWidgetViewModel {
    private(set) var tiles: [DoMoreWithMegaTile] = []

    @ObservationIgnored
    @PreferenceWrapper(key: PreferenceKeyEntity.isCameraUploadsEnabled, defaultValue: false)
    private var isCameraUploadsEnabled: Bool

    @ObservationIgnored private let actionHandler: any DoMoreWithMegaActionHandling

    init(
        actionHandler: some DoMoreWithMegaActionHandling,
        preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase(repository: PreferenceRepository.newRepo)
    ) {
        self.actionHandler = actionHandler
        $isCameraUploadsEnabled.useCase = preferenceUseCase
    }

    func refreshTiles() {
        tiles = DoMoreWithMegaTile.allCases.filter { $0 != .cameraUploads || !isCameraUploadsEnabled }
    }

    func didTap(_ tile: DoMoreWithMegaTile) {
        actionHandler.handleAction(tile)
    }
}
