import MEGADomain
import MEGAL10n
import MEGAPreference
import MEGASwiftUI
import Observation

@Observable @MainActor
final class DoMoreWithMegaWidgetViewModel {
    private(set) var tiles: [DoMoreWithMegaTile] = []
    var action: DoMoreWithMegaAction?
    var createAlbumRequest: CreateAlbumAlertInput?

    @ObservationIgnored
    @PreferenceWrapper(key: PreferenceKeyEntity.isCameraUploadsEnabled, defaultValue: false)
    private var isCameraUploadsEnabled: Bool

    @ObservationIgnored private let createAlbumUseCase: any CreateAlbumUseCaseProtocol

    init(
        createAlbumUseCase: some CreateAlbumUseCaseProtocol,
        preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase(repository: PreferenceRepository.newRepo)
    ) {
        self.createAlbumUseCase = createAlbumUseCase
        $isCameraUploadsEnabled.useCase = preferenceUseCase
    }

    func refreshTiles() {
        tiles = DoMoreWithMegaTile.allCases.filter { $0 != .cameraUploads || !isCameraUploadsEnabled }
    }

    func didTap(_ tile: DoMoreWithMegaTile) async {
        switch tile {
        case .cameraUploads: action = .cameraUploads
        case .scanDoc: action = .scanDoc
        case .createAlbum: await handleCreateAlbumTap()
        case .addContacts: action = .addContacts
        case .scheduleMeeting: action = .scheduleMeeting
        }
    }

    func createAlbum(named name: String) async -> SnackBar {
        do {
            let album = try await createAlbumUseCase.createAlbum(named: name)
            return SnackBar(
                message: Strings.Localizable.Home.DoMoreWithMega.AlbumCreated.message(album.name),
                action: .init(title: Strings.Localizable.Home.DoMoreWithMega.AlbumCreated.seeAlbum) { [weak self] in
                    self?.action = .album(album)
                }
            )
        } catch {
            return SnackBar(message: Strings.Localizable.somethingWentWrong)
        }
    }

    // MARK: - Tile handlers

    private func handleCreateAlbumTap() async {
        guard !createAlbumUseCase.isOverDiskQuota else {
            action = .overDiskQuota
            return
        }
        createAlbumRequest = CreateAlbumAlertInput(
            albumNames: await createAlbumUseCase.existingAlbumNames()
        )
    }
}
