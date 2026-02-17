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
            let sut = makeSUT(
                album: album,
                thumbnailUseCase: MockThumbnailUseCase(
                    loadThumbnailResult: .success(thumbnailEntity)),
                monitorUserAlbumPhotosUseCase: monitorUserAlbumPhotosUseCase,
                sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
                albumCoverUseCase: MockAlbumCoverUseCase(albumCover: coverNode))
            
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
        let sut = makeSUT(
            album: album,
            monitorUserAlbumPhotosUseCase: monitorUserAlbumPhotosUseCase)
        
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
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> GetLinkAlbumInfoCellViewModel {
        let sut = GetLinkAlbumInfoCellViewModel(
            album: album,
            thumbnailUseCase: thumbnailUseCase,
            monitorUserAlbumPhotosUseCase: monitorUserAlbumPhotosUseCase,
            sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
            albumCoverUseCase: albumCoverUseCase)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
