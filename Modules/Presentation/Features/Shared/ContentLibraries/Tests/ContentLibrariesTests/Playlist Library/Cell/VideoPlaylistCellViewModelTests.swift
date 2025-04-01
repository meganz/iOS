import AsyncAlgorithms
@testable import ContentLibraries
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGATest
import SwiftUI
import Testing
import XCTest

final class VideoPlaylistCellViewModelTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        cleanTestArtifacts()
        writeCacheImage()
    }
    
    override func tearDown() {
        super.tearDown()
        cleanTestArtifacts()
    }
    
    // MARK: - onViewAppeared
    
    @MainActor
    func testOnViewAppear_whenLoad_loadThumbnailsFromThumbnailLoader() async {
        let videoPlaylist = videoPlaylistEntity(name: "name", handle: 1)
        let allVideos = [ [nodeEntity(name: "video 1", handle: 1, hasThumbnail: true)] ].async.eraseToAnyAsyncSequence()
        let (sut, videoPlaylistThumbnailLoader) = makeSUT(
            videoPlaylistEntity: videoPlaylist,
            videoPlaylistContentUseCase: MockVideoPlaylistContentUseCase(monitorUserVideoPlaylistContentAsyncSequenceResult: allVideos)
        )
        
        await sut.onViewAppear()
        
        XCTAssertEqual(videoPlaylistThumbnailLoader.loadThumbnailsCallCount, 1)
    }
    
    @MainActor
    func testOnViewAppear_whenNoCachedThumbnailsThumbnailAndErrors_deliversPlaceholderImage() async {
        let videoPlaylist = videoPlaylistEntity(name: "name", handle: 1)
        let videos = [ [ nodeEntity(name: "video 1", handle: 1, hasThumbnail: true) ] ].async.eraseToAnyAsyncSequence()
        let (sut, _) = makeSUT(
            videoPlaylistEntity: videoPlaylist,
            videoPlaylistContentUseCase: MockVideoPlaylistContentUseCase(monitorUserVideoPlaylistContentAsyncSequenceResult: videos)
        )
        
        await sut.onViewAppear()
        
        let previewEntity = sut.previewEntity
        previewEntity.thumbnail.imageContainers.enumerated().forEach { (index, imageContainer) in
            XCTAssertEqual(imageContainer.image, Image(systemName: "square.fill"), "Failed at index: \(index), with data: \(imageContainer)")
        }
    }
    
    @MainActor
    func testOnViewAppear_whenHasCachedThumbnailThumbnailAndErrors_deliversImage() async {
        let videoPlaylist = videoPlaylistEntity(name: "name", handle: 1)
        let videos = [ [nodeEntity(name: "video 1", handle: 1, hasThumbnail: true)] ].async.eraseToAnyAsyncSequence()
        let (sut, _) = makeSUT(
            videoPlaylistEntity: videoPlaylist,
            videoPlaylistContentUseCase: MockVideoPlaylistContentUseCase(monitorUserVideoPlaylistContentAsyncSequenceResult: videos)
        )
        
        await sut.onViewAppear()
        
        let previewEntity = sut.previewEntity
        previewEntity.thumbnail.imageContainers.enumerated().forEach { (index, imageContainer) in
            XCTAssertNotNil(imageContainer, "Failed at index: \(index), with data: \(imageContainer)")
        }
    }
    
    @MainActor
    func testOnViewAppear_whenSucessLoadThumbnail_useLoadedImage() async {
        let videoPlaylist = videoPlaylistEntity(name: "name", handle: 1)
        let videos = [ [nodeEntity(name: "video 1", handle: 1, hasThumbnail: true)] ].async.eraseToAnyAsyncSequence()
        let (sut, _) = makeSUT(
            videoPlaylistEntity: videoPlaylist,
            videoPlaylistContentUseCase: MockVideoPlaylistContentUseCase(monitorUserVideoPlaylistContentAsyncSequenceResult: videos)
        )
        
        await sut.onViewAppear()
        
        let previewEntity = sut.previewEntity
        previewEntity.thumbnail.imageContainers.enumerated().forEach { (index, imageContainer) in
            XCTAssertNotNil(imageContainer, "Failed at index: \(index), with data: \(imageContainer)")
        }
    }
    
    // MARK: - onTappedMoreOptions
    
    @MainActor
    func testOnTappedMoreOptions_whenCalled_triggerTap() async {
        let videoPlaylist = videoPlaylistEntity(name: "name", handle: 1)
        var tappedVideoPlaylists = [VideoPlaylistEntity]()
        let allVideos = [ [ nodeEntity(name: "video 1", handle: 1, hasThumbnail: true) ] ].async.eraseToAnyAsyncSequence()
        let (sut, _) = makeSUT(
            videoPlaylistEntity: videoPlaylist,
            videoPlaylistContentUseCase: MockVideoPlaylistContentUseCase(monitorUserVideoPlaylistContentAsyncSequenceResult: allVideos),
            onTapMoreOptions: { tappedVideoPlaylists.append($0) }
        )
        
        sut.onTappedMoreOptions()
        
        XCTAssertEqual(tappedVideoPlaylists, [ videoPlaylist ])
    }
    
    // MARK: - previewEntity
    
    @MainActor
    func testPreviewEntity_whenOnViewAppeared_createsCorrectEntity() async {
        let videoPlaylist = videoPlaylistEntity(name: "name", handle: 1, sharedLinkStatus: .exported(true), count: 2)
        let allVideos = [[
            nodeEntity(name: "video 1", handle: 1, hasThumbnail: true, duration: 30),
            nodeEntity(name: "video 2", handle: 2, hasThumbnail: true, duration: 30)
        ]].async.eraseToAnyAsyncSequence()
        let (sut, _) = makeSUT(
            videoPlaylistEntity: videoPlaylist,
            videoPlaylistContentUseCase: MockVideoPlaylistContentUseCase(monitorUserVideoPlaylistContentAsyncSequenceResult: allVideos)
        )
        
        await sut.onViewAppear()
        
        assertThatPreviewEntityCreatesCorrectly(on: sut, videoPlaylist: videoPlaylist)
    }
    
    // MARK: - secondaryInformationViewType
    
    @MainActor
    func testSecondaryInformationViewType_whenEntityCountZero_showEmptyPlaylistView() async {
        let videoPlaylist = videoPlaylistEntity(name: "name", handle: 1, count: 0)
        let (sut, _) = makeSUT(
            videoPlaylistEntity: videoPlaylist
        )
        
        let result = sut.secondaryInformationViewType
        
        XCTAssertEqual(result, .emptyPlaylist)
    }
    
    @MainActor
    func testSecondaryInformationViewType_whenVideosCountNotZero_showInformationView() async {
        let nonZeroRandomCount = Int.random(in: 1...10000)
        let videoPlaylist = videoPlaylistEntity(name: "name", handle: 1, count: nonZeroRandomCount)
        let videos = [ (0...nonZeroRandomCount).map { nodeEntity(name: "video-\($0)", handle: SetHandleEntity($0), hasThumbnail: true) } ].async.eraseToAnyAsyncSequence()
        let (sut, _) = makeSUT(
            videoPlaylistEntity: videoPlaylist,
            videoPlaylistContentUseCase: MockVideoPlaylistContentUseCase(monitorUserVideoPlaylistContentAsyncSequenceResult: videos)
        )
        await sut.onViewAppear()
        
        let result = sut.secondaryInformationViewType
        
        XCTAssertEqual(result, .information)
    }
    
    // MARK: - isLoading
    
    @MainActor
    func testIsLoading_whenInit_ShowsLoading() async {
        let videoPlaylist = videoPlaylistEntity(name: "name", handle: 1, count: 0)
        let (sut, _) = makeSUT(
            videoPlaylistEntity: videoPlaylist
        )
        
        XCTAssertTrue(sut.isLoading)
    }
    
    @MainActor
    func testIsLoading_whenOnAppear_disableLoadingAfterDisplayablePropertiesAreSet() async {
        let videoPlaylist = videoPlaylistEntity(name: "name", handle: 1, sharedLinkStatus: .exported(true), count: 2)
        let allVideos = [[
            nodeEntity(name: "video 1", handle: 1, hasThumbnail: true, duration: 30),
            nodeEntity(name: "video 2", handle: 2, hasThumbnail: true, duration: 30)
        ]].async.eraseToAnyAsyncSequence()
        let (sut, _) = makeSUT(
            videoPlaylistEntity: videoPlaylist,
            videoPlaylistContentUseCase: MockVideoPlaylistContentUseCase(monitorUserVideoPlaylistContentAsyncSequenceResult: allVideos)
        )
        
        XCTAssertTrue(sut.isLoading)
        
        await sut.onViewAppear()
        
        assertThatPreviewEntityCreatesCorrectly(on: sut, videoPlaylist: videoPlaylist)
        XCTAssertEqual(sut.secondaryInformationViewType, .information)
        XCTAssertFalse(sut.isLoading)
    }
    
    // MARK: - Helpers
    
    @MainActor
    private func makeSUT(
        videoPlaylistEntity: VideoPlaylistEntity,
        videoPlaylistContentUseCase: MockVideoPlaylistContentUseCase = MockVideoPlaylistContentUseCase(),
        setSelection: SetSelection = SetSelection(),
        onTapMoreOptions: @escaping (_ node: VideoPlaylistEntity) -> Void = { _ in },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: VideoPlaylistCellViewModel,
        videoPlaylistThumbnailLoader: MockVideoPlaylistThumbnailLoader
    ) {
        let videoPlaylistThumbnailLoader = MockVideoPlaylistThumbnailLoader()
        let sut = VideoPlaylistCellViewModel(
            videoPlaylistThumbnailLoader: videoPlaylistThumbnailLoader,
            videoPlaylistContentUseCase: videoPlaylistContentUseCase, 
            sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase(sortOrderEntity: .creationAsc),
            videoPlaylistEntity: videoPlaylistEntity,
            setSelection: setSelection,
            onTapMoreOptions: onTapMoreOptions
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return (sut, videoPlaylistThumbnailLoader)
    }
    
    private func videoPlaylistEntity(name: String, handle: SetHandleEntity, sharedLinkStatus: SharedLinkStatusEntity = .exported(false), type: VideoPlaylistEntityType = .user, count: Int = 0) -> VideoPlaylistEntity {
        VideoPlaylistEntity(
            setIdentifier: SetIdentifier(handle: handle),
            name: name,
            count: count,
            type: type,
            creationTime: Date(),
            modificationTime: Date(),
            sharedLinkStatus: sharedLinkStatus
        )
    }
    
    private func nodeEntity(name: String, handle: SetHandleEntity, hasThumbnail: Bool, isPublic: Bool = false, isShare: Bool = false, isFavorite: Bool = false, label: NodeLabelTypeEntity = .blue, size: UInt64 = 1, duration: Int = 60) -> NodeEntity {
        NodeEntity(
            changeTypes: .name,
            nodeType: .folder,
            name: name,
            handle: handle,
            hasThumbnail: hasThumbnail,
            hasPreview: true,
            isPublic: isPublic,
            isShare: isShare,
            isFavourite: isFavorite,
            label: label,
            publicHandle: handle,
            size: size,
            duration: duration,
            mediaType: .video
        )
    }
    
    private func imagePathData() -> (imagePath: String, imageData: Data?, imageURL: URL?) {
        let testImagePath = NSTemporaryDirectory() + "test_image.jpg"
        
        let imageData = UIImage(systemName: "square")?.jpegData(compressionQuality: 1.0)
        
        let url = URL(string: testImagePath)
        
        return (testImagePath, imageData, url)
    }
    
    private func writeCacheImage() {
        let (testImagePath, imageData, _) = imagePathData()
        XCTAssertNotNil(imageData)
        XCTAssertTrue(FileManager.default.createFile(atPath: testImagePath, contents: imageData, attributes: nil))
    }
    
    private func cleanTestArtifacts() {
        let (testImagePath, _, _) = imagePathData()
        try? FileManager.default.removeItem(atPath: testImagePath)
    }
    
    @MainActor
    private func assertThatPreviewEntityCreatesCorrectly(
        on sut: VideoPlaylistCellViewModel,
        videoPlaylist: VideoPlaylistEntity,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(sut.previewEntity.title, videoPlaylist.name, file: file, line: line)
        XCTAssertEqual(sut.previewEntity.count, "\(videoPlaylist.count) Videos", file: file, line: line)
        XCTAssertEqual(sut.previewEntity.isExported, videoPlaylist.isLinkShared, file: file, line: line)
        XCTAssertEqual(sut.previewEntity.duration, "01:00", file: file, line: line)
        XCTAssertEqual(sut.previewEntity.thumbnail.imageContainers.count, videoPlaylist.count, file: file, line: line)
    }
}

@Suite("VideoPlaylistCellViewModel Tests")
struct VideoPlaylistCellViewModelTestSuite {
    @Suite("Set selection")
    @MainActor
    struct SetSelectionSuite {
        @Test("when edit mode is editing selection should be enabled",
              arguments: [(EditMode.active, true),
                          (EditMode.inactive, false),
                          (EditMode.transient, true)])
        func isSelectionEnabled(mode: EditMode, expectedSelectionEnabled: Bool) async {
            let setSelection = SetSelection(editMode: mode)
            let sut = makeSUT(
                videoPlaylistEntity: .init(
                    setIdentifier: SetIdentifier(handle: 1)),
                setSelection: setSelection)
            
            #expect(sut.isSelectionEnabled == expectedSelectionEnabled)
        }
        
        @Test("when item selected then it should set isSelected",
              arguments: [(SetIdentifier(handle: 1), true),
                          (SetIdentifier(handle: 2), false)])
        func isSelectionEnabled(selectedIdentifier: SetIdentifier, expectedSelection: Bool) async {
            let setSelection = SetSelection()
            let sut = makeSUT(
                videoPlaylistEntity: .init(
                    setIdentifier: SetIdentifier(handle: 1)),
                setSelection: setSelection)
            
            setSelection.toggle(selectedIdentifier)
            
            #expect(sut.isSelected == expectedSelection)
        }
    }
    
    @MainActor
    private static func makeSUT(
        videoPlaylistThumbnailLoader: some VideoPlaylistThumbnailLoaderProtocol = MockVideoPlaylistThumbnailLoader(),
        videoPlaylistContentUseCase: some VideoPlaylistContentsUseCaseProtocol = MockVideoPlaylistContentUseCase(),
        sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol = MockSortOrderPreferenceUseCase(sortOrderEntity: .creationAsc),
        videoPlaylistEntity: VideoPlaylistEntity,
        setSelection: SetSelection = SetSelection(),
        onTapMoreOptions: @escaping (_ node: VideoPlaylistEntity) -> Void = { _ in }
    ) -> VideoPlaylistCellViewModel {
        .init(
            videoPlaylistThumbnailLoader: videoPlaylistThumbnailLoader,
            videoPlaylistContentUseCase: videoPlaylistContentUseCase,
            sortOrderPreferenceUseCase: sortOrderPreferenceUseCase,
            videoPlaylistEntity: videoPlaylistEntity,
            setSelection: setSelection,
            onTapMoreOptions: onTapMoreOptions)
    }
}
