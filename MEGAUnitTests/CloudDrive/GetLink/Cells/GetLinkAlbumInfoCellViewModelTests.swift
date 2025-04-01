@testable import MEGA
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGASwift
import MEGATest
import XCTest

final class GetLinkAlbumInfoCellViewModelTests: XCTestCase {
    @MainActor func testDispatch_onViewReadyWithAlbumCover_shouldSetLabelsAndUpdateThumbnail() throws {
        let localImage = try XCTUnwrap(UIImage(systemName: "folder"))
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isLocalFileCreated = FileManager.default.createFile(atPath: localURL.path, contents: localImage.pngData())
        XCTAssertTrue(isLocalFileCreated)
        
        let albumName = "Fruit"
        let albumCount = 45
        let album = AlbumEntity(id: 5, name: albumName, coverNode: NodeEntity(handle: 50), count: albumCount, type: .user)
        let sut = makeSUT(album: album,
                          thumbnailUseCase: MockThumbnailUseCase(loadThumbnailResult: .success(ThumbnailEntity(url: localURL, type: .thumbnail))))
        
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .setLabels(title: albumName,
                       subtitle: Strings.Localizable.General.Format.Count.items(albumCount)),
            .setThumbnail(path: localURL.path)
        ])
    }
    
    @MainActor func testDispatch_onViewReadyWithErrorAlbumCover_shouldSetLabelsAndSetPlaceholderThumbnail() throws {
        let albumName = "Fruit"
        let albumCount = 45
        let album = AlbumEntity(id: 5, name: albumName, coverNode: NodeEntity(handle: 50), count: albumCount, type: .user)
        let sut = makeSUT(album: album,
                          thumbnailUseCase: MockThumbnailUseCase(loadThumbnailResult: .failure(GenericErrorEntity())))
        
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .setLabels(title: albumName,
                       subtitle: Strings.Localizable.General.Format.Count.items(albumCount)),
            .setPlaceholderThumbnail
        ])
    }
    
    @MainActor func testDispatch_onViewReadyWithOutAlbumCover_shouldOnlySetLabels() throws {
        let albumName = "Fruit"
        let albumCount = 45
        let album = AlbumEntity(id: 5, name: albumName, count: albumCount, type: .user)
        let sut = makeSUT(album: album,
                          thumbnailUseCase: MockThumbnailUseCase())
        
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .setLabels(title: albumName,
                       subtitle: Strings.Localizable.General.Format.Count.items(albumCount)),
            .setPlaceholderThumbnail
        ])
    }
    
    @MainActor
    func testDispatchOnViewReady_photosCoverThumbnailLoaded_shouldSetAlbumCoverAndCount() async throws {
        for excludeSensitives in [true, false] {
            let albumName = "Test"
            let album = AlbumEntity(id: 5, name: albumName, type: .user)
            let coverNode = NodeEntity(handle: 4)
            let albumPhotos = [AlbumPhotoEntity(photo: coverNode)]
            let userAlbumPhotosAsyncSequence = SingleItemAsyncSequence(item: albumPhotos)
            let thumbnailURL = try makeImageURL()
            let thumbnailEntity = ThumbnailEntity(url: thumbnailURL, type: .thumbnail)
            let monitorUserAlbumPhotosUseCase = MockMonitorUserAlbumPhotosUseCase(
                monitorUserAlbumPhotosAsyncSequence: userAlbumPhotosAsyncSequence.eraseToAnyAsyncSequence())
            let sensitiveDisplayPreferenceUseCase = MockSensitiveDisplayPreferenceUseCase(
                excludeSensitives: excludeSensitives)
            let albumRemoteFeatureFlagProvider = MockAlbumRemoteFeatureFlagProvider(isEnabled: true)
            let sut = makeSUT(
                album: album,
                thumbnailUseCase: MockThumbnailUseCase(
                    loadThumbnailResult: .success(thumbnailEntity)),
                monitorUserAlbumPhotosUseCase: monitorUserAlbumPhotosUseCase,
                sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
                albumCoverUseCase: MockAlbumCoverUseCase(albumCover: coverNode),
                albumRemoteFeatureFlagProvider: albumRemoteFeatureFlagProvider)
            
            await test(viewModel: sut, action: .onViewReady, expectedCommands: [
                .setLabels(title: albumName,
                           subtitle: Strings.Localizable.General.Format.Count.items(albumPhotos.count)),
                .setThumbnail(path: thumbnailURL.path)
            ])
            
            await sut.loadingTask?.value
            XCTAssertEqual(monitorUserAlbumPhotosUseCase.invocations,
                           [.userAlbumPhotos(excludeSensitives: excludeSensitives)])
        }
    }
    
    @MainActor
    func testDispatchOnViewReady_photosLoaded_shouldSetCountAndPlaceholder() async throws {
        let albumName = "Test"
        let album = AlbumEntity(id: 5, name: albumName, type: .user)
        let monitorUserAlbumPhotosUseCase = MockMonitorUserAlbumPhotosUseCase(
            monitorUserAlbumPhotosAsyncSequence: SingleItemAsyncSequence(item: []).eraseToAnyAsyncSequence())
        let albumRemoteFeatureFlagProvider = MockAlbumRemoteFeatureFlagProvider(isEnabled: true)
        let sut = makeSUT(
            album: album,
            monitorUserAlbumPhotosUseCase: monitorUserAlbumPhotosUseCase,
            albumRemoteFeatureFlagProvider: albumRemoteFeatureFlagProvider)
        
        await test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .setLabels(title: albumName,
                       subtitle: Strings.Localizable.General.Format.Count.items(0)),
            .setPlaceholderThumbnail
        ])
        
        await sut.loadingTask?.value
    }
    
    @MainActor
    func testDispatch_cancelTasks_shouldCancelTasks() {
        let sut = makeSUT()
        
        sut.dispatch(.cancelTasks)
        
        XCTAssertNil(sut.loadingTask)
    }
    
    @MainActor
    private func makeSUT(
        album: AlbumEntity = AlbumEntity(id: 1, type: .user),
        thumbnailUseCase: some ThumbnailUseCaseProtocol = MockThumbnailUseCase(),
        monitorUserAlbumPhotosUseCase: some MonitorUserAlbumPhotosUseCaseProtocol = MockMonitorUserAlbumPhotosUseCase(),
        sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol = MockSensitiveDisplayPreferenceUseCase(),
        albumCoverUseCase: some AlbumCoverUseCaseProtocol = MockAlbumCoverUseCase(),
        albumRemoteFeatureFlagProvider: some AlbumRemoteFeatureFlagProviderProtocol = MockAlbumRemoteFeatureFlagProvider(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> GetLinkAlbumInfoCellViewModel {
        let sut = GetLinkAlbumInfoCellViewModel(
            album: album,
            thumbnailUseCase: thumbnailUseCase,
            monitorUserAlbumPhotosUseCase: monitorUserAlbumPhotosUseCase,
            sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
            albumCoverUseCase: albumCoverUseCase,
            albumRemoteFeatureFlagProvider: albumRemoteFeatureFlagProvider)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
