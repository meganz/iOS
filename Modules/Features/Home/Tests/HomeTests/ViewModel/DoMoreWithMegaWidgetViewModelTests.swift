@testable import Home
import MEGADomain
import MEGAPreferenceMocks
import Testing

@Suite("DoMoreWithMegaWidgetViewModel")
@MainActor
struct DoMoreWithMegaWidgetViewModelTests {
    @Test("Camera uploads never set or off shows all tiles in design order", arguments: [nil, false])
    func cameraUploadsOffShowsAllTiles(isCameraUploadsEnabled: Bool?) {
        let sut = makeSUT(isCameraUploadsEnabled: isCameraUploadsEnabled).sut

        sut.refreshTiles()

        #expect(sut.tiles == [.cameraUploads, .scanDoc, .createAlbum, .addContacts, .scheduleMeeting])
    }

    @Test("Camera uploads on hides only the Camera uploads tile")
    func cameraUploadsOnHidesCameraUploadsTile() {
        let sut = makeSUT(isCameraUploadsEnabled: true).sut

        sut.refreshTiles()

        #expect(sut.tiles == [.scanDoc, .createAlbum, .addContacts, .scheduleMeeting])
    }

    @Test("refreshing reads the Camera uploads setting again")
    func refreshReadsSettingAgain() {
        let (sut, preferenceUseCase) = makeSUT(isCameraUploadsEnabled: false)
        sut.refreshTiles()

        preferenceUseCase.dict[PreferenceKeyEntity.isCameraUploadsEnabled.rawValue] = true
        sut.refreshTiles()

        #expect(!sut.tiles.contains(.cameraUploads))
    }

    @Test("tapping a tile passes it to the action handler")
    func tapPassesTileToActionHandler() {
        let actionHandler = SpyDoMoreWithMegaActionHandler()
        let sut = DoMoreWithMegaWidgetViewModel(actionHandler: actionHandler, preferenceUseCase: MockPreferenceUseCase())

        sut.didTap(.scanDoc)

        #expect(actionHandler.tiles == [.scanDoc])
    }

    // MARK: - Helpers

    private func makeSUT(
        isCameraUploadsEnabled: Bool?
    ) -> (sut: DoMoreWithMegaWidgetViewModel, preferenceUseCase: MockPreferenceUseCase) {
        let preferenceUseCase = MockPreferenceUseCase(
            dict: isCameraUploadsEnabled.map { [PreferenceKeyEntity.isCameraUploadsEnabled.rawValue: $0] } ?? [:]
        )
        let sut = DoMoreWithMegaWidgetViewModel(actionHandler: SpyDoMoreWithMegaActionHandler(), preferenceUseCase: preferenceUseCase)
        return (sut, preferenceUseCase)
    }
}

@MainActor
private final class SpyDoMoreWithMegaActionHandler: DoMoreWithMegaActionHandling {
    private(set) var tiles: [DoMoreWithMegaTile] = []

    func handleAction(_ tile: DoMoreWithMegaTile) {
        tiles.append(tile)
    }
}
