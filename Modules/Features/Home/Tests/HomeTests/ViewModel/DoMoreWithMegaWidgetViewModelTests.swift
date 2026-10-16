@testable import Home
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPreferenceMocks
import MEGASwiftUI
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

    @Test("tapping Scan doc publishes the scan doc action")
    func tapScanDocPublishesAction() async {
        let sut = makeSUT().sut

        await sut.didTap(.scanDoc)

        #expect(sut.action == .scanDoc)
    }

    // MARK: - Create album

    @Test("Create album on a paywalled account publishes the over quota action and shows no alert")
    func createAlbumPaywalledPublishesOverQuota() async {
        let sut = makeSUT(isOverDiskQuota: true).sut

        await sut.didTap(.createAlbum)

        #expect(sut.action == .overDiskQuota)
        #expect(sut.createAlbumRequest == nil)
    }

    @Test("Create album within quota asks for the alert with the existing album names")
    func createAlbumWithinQuotaShowsAlert() async {
        let sut = makeSUT(albumNames: ["Trip"]).sut

        await sut.didTap(.createAlbum)

        #expect(sut.createAlbumRequest?.albumNames == ["Trip"])
        #expect(sut.action == nil)
    }

    @Test("Create with an empty name in the alert creates the next free default name")
    func emptyNameUsesDefaultName() {
        let defaultName = Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder
        let spy = SpyCreateAlbum()
        let alert = TextFieldAlertViewModel.createAlbum(albumNames: [defaultName], create: spy.create)

        alert.action?("")

        #expect(spy.names == ["\(defaultName) (1)"])
    }

    @Test("created album shows a snackbar whose action publishes the album action")
    func createSuccessShowsSnackBarWithSeeAlbum() async {
        let sut = makeSUT().sut

        let snackBar = await sut.createAlbum(named: "Trip")
        snackBar.action?.handler()

        #expect(snackBar.message == Strings.Localizable.Home.DoMoreWithMega.AlbumCreated.message("Trip"))
        #expect(snackBar.action?.title == Strings.Localizable.Home.DoMoreWithMega.AlbumCreated.seeAlbum)
        #expect(sut.action == .album(MockAlbumListUseCase.sampleUserAlbum(name: "Trip")))
    }

    @Test("create failure shows the generic error snackbar")
    func createFailureShowsError() async {
        let sut = makeSUT(createFails: true).sut

        let snackBar = await sut.createAlbum(named: "Trip")

        #expect(snackBar.message == Strings.Localizable.somethingWentWrong)
        #expect(snackBar.action == nil)
    }

    // MARK: - Helpers

    private func makeSUT(
        isCameraUploadsEnabled: Bool? = nil,
        isOverDiskQuota: Bool = false,
        albumNames: [String] = [],
        createFails: Bool = false
    ) -> (sut: DoMoreWithMegaWidgetViewModel, preferenceUseCase: MockPreferenceUseCase) {
        let preferenceUseCase = MockPreferenceUseCase(
            dict: isCameraUploadsEnabled.map { [PreferenceKeyEntity.isCameraUploadsEnabled.rawValue: $0] } ?? [:]
        )
        let sut = DoMoreWithMegaWidgetViewModel(
            createAlbumUseCase: MockCreateAlbumUseCase(
                isOverDiskQuota: isOverDiskQuota,
                albumNames: albumNames,
                createFails: createFails
            ),
            preferenceUseCase: preferenceUseCase
        )
        return (sut, preferenceUseCase)
    }
}

private struct MockCreateAlbumUseCase: CreateAlbumUseCaseProtocol {
    let isOverDiskQuota: Bool
    let albumNames: [String]
    let createFails: Bool

    func existingAlbumNames() async -> [String] {
        albumNames
    }

    func createAlbum(named name: String) async throws -> AlbumEntity {
        guard !createFails else { throw AlbumErrorEntity.generic }
        return MockAlbumListUseCase.sampleUserAlbum(name: name)
    }
}

@MainActor
private final class SpyCreateAlbum {
    private(set) var names: [String] = []

    func create(_ name: String) {
        names.append(name)
    }
}
