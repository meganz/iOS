import Combine
@testable import MEGA
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import MEGASwift
import MEGASwiftUI
import MEGATest
import SwiftUI
import XCTest

final class AlbumCellViewModelTests: XCTestCase {
    private let album = AlbumEntity(id: 1, name: "Test", coverNode: NodeEntity(handle: 1), count: 15, type: .favourite)
    private var subscriptions = Set<AnyCancellable>()
    
    func testInit_setTitleNodesAndTitlePublishers() throws {
        let sut = makeAlbumCellViewModel(album: album)
        
        XCTAssertEqual(sut.title, album.name)
        XCTAssertEqual(sut.numberOfNodes, album.count)
        XCTAssertTrue(sut.thumbnailContainer.type == .placeholder)
        XCTAssertFalse(sut.isLoading)
    }
    
    func testInit_album_noCover_shouldSetCorrectThumbnail() {
        let sut = makeAlbumCellViewModel(album: AlbumEntity(id: 5, type: .user))
        XCTAssertTrue(sut.thumbnailContainer.isEqual(ImageContainer(image: Image(.placeholder), type: .placeholder)))
    }
    
    func testLoadAlbumThumbnail_onThumbnailLoaded_loadingStateIsCorrect() async throws {
        let thumbnailContainer = ImageContainer(image: Image("folder"), type: .thumbnail)
        let thumbnailLoader = MockThumbnailLoader(loadImage: makeThumbnailAsyncSequence(container: thumbnailContainer))
        let sut = makeAlbumCellViewModel(album: album,
                                         thumbnailLoader: thumbnailLoader)
        
        let exp = expectation(description: "loading should change during loading of albums")
        exp.expectedFulfillmentCount = 2
        
        var results = [Bool]()
        sut.$isLoading
            .dropFirst()
            .sink {
                results.append($0)
                exp.fulfill()
            }.store(in: &subscriptions)
        
        await sut.loadAlbumThumbnail()
        
        await fulfillment(of: [exp], timeout: 1.0)
        XCTAssertEqual(results, [true, false])
    }
    
    func testLoadAlbumThumbnail_onLoadThumbnail_thumbnailContainerIsUpdatedWithLoadedImageIfContainerIsCurrentlyPlaceholder() async throws {
        let thumbnailContainer = ImageContainer(image: Image("folder"), type: .thumbnail)
        let thumbnailLoader = MockThumbnailLoader(loadImage: makeThumbnailAsyncSequence(container: thumbnailContainer))
        let sut = makeAlbumCellViewModel(album: album,
                                         thumbnailLoader: thumbnailLoader)
        
        await sut.loadAlbumThumbnail()
        
        XCTAssertTrue(sut.thumbnailContainer.isEqual(thumbnailContainer))
    }
    
    func testLoadAlbumThumbnail_onLoadThumbnailFailed_thumbnailIsNotUpdatedAndLoadedIsFalse() async throws {
        let sut = makeAlbumCellViewModel(album: album)
        let exp = expectation(description: "thumbnail should not change")
        exp.isInverted = true
        
        sut.$thumbnailContainer
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        
        await sut.loadAlbumThumbnail()
        
        await fulfillment(of: [exp], timeout: 1.0)
        XCTAssertFalse(sut.isLoading)
    }
    
    func testThumbnailContainer_cachedThumbnail_setThumbnailContainerWithoutPlaceholder() async throws {
        let thumbnailContainer = ImageContainer(image: Image("folder"), type: .thumbnail)
        let thumbnailLoader = MockThumbnailLoader(initialImage: thumbnailContainer)
        
        let sut = makeAlbumCellViewModel(album: album,
                                         thumbnailLoader: thumbnailLoader)
        
        XCTAssertTrue(sut.thumbnailContainer.isEqual(thumbnailContainer))
        
        let exp = expectation(description: "thumbnail should not update again")
        exp.isInverted = true
        sut.$thumbnailContainer
            .dropFirst()
            .sink {_ in
                exp.fulfill()
            }.store(in: &subscriptions)
        
        await sut.loadAlbumThumbnail()
        
        await fulfillment(of: [exp], timeout: 1.0)
        XCTAssertTrue(sut.thumbnailContainer.isEqual(thumbnailContainer))
    }
    
    func testLoadAlbumThumbnail_cachedThumbnail_shouldNotLoadThumbnailAgain() async throws {
        let thumbnailContainer = ImageContainer(image: Image("folder"), type: .thumbnail)
        let thumbnailLoader = MockThumbnailLoader(initialImage: thumbnailContainer)
        
        let sut = makeAlbumCellViewModel(album: album,
                                         thumbnailLoader: thumbnailLoader)
        XCTAssertTrue(sut.thumbnailContainer.isEqual(thumbnailContainer))
        
        let exp = expectation(description: "loading flag should not change")
        exp.isInverted = true
        sut.$isLoading
            .dropFirst()
            .sink {_ in
                exp.fulfill()
            }.store(in: &subscriptions)
        
        await sut.loadAlbumThumbnail()
        
        await fulfillment(of: [exp], timeout: 1.0)
        XCTAssertFalse(sut.isLoading)
    }
    
    func testIsSelected_whenUserTapOnAlbum_shouldBeSelected() {
        let selection = AlbumSelection()
        let sut = makeAlbumCellViewModel(album: album,
                                         selection: selection)
        
        sut.isSelected = true
        
        XCTAssertTrue(selection.isAlbumSelected(album))
    }
    
    func testShouldShowEditStateOpacity_whenAlbumListEditingAndonUserAlbum_shouldReturnRightValue() {
        let selection = AlbumSelection()
        let userAlbum1 = AlbumEntity(id: 4, name: "Album 1", coverNode: NodeEntity(handle: 3),
                                     count: 1, type: .user, modificationTime: nil)
        let sut = makeAlbumCellViewModel(album: userAlbum1,
                                         selection: selection )
        
        let exp = expectation(description: "Should set shouldShowEditStateOpacity to 1.0")
        exp.expectedFulfillmentCount = 2
        
        var result = [Double]()
        
        sut.$shouldShowEditStateOpacity
            .dropFirst()
            .sink {
                result.append($0)
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        selection.editMode = .active
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(result, [0.0, 1.0])
    }
    
    func testShouldShowEditStateOpacity_whenAlbumListEditingAndonSystemAlbum_shouldReturnRightValue() {
        let selection = AlbumSelection()
        let systemAlbum = AlbumEntity(id: 4, name: "Gif", coverNode: NodeEntity(handle: 3),
                                      count: 1, type: .gif, modificationTime: nil)
        let sut = makeAlbumCellViewModel(album: systemAlbum,
                                         selection: selection)
        
        let exp = expectation(description: "Should set shouldShowEditStateOpaicity to 0.0")
        exp.expectedFulfillmentCount = 2
        
        var result = [Double]()
        
        sut.$shouldShowEditStateOpacity
            .dropFirst()
            .sink {
                result.append($0)
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        selection.editMode = .active
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(result, [0.0, 0.0])
    }
    
    func testOpacity_whenAlbumListEditingAndUserAlbum_shouldReturnRightValue() {
        let selection = AlbumSelection()
        let userAlbum1 = AlbumEntity(id: 4, name: "Album 1", coverNode: NodeEntity(handle: 3),
                                     count: 1, type: .user, modificationTime: nil)
        let sut = makeAlbumCellViewModel(album: userAlbum1,
                                         selection: selection)
        
        let exp = expectation(description: "Should set shouldShowEditStateOpacity to 1.0")
        exp.expectedFulfillmentCount = 2
        
        var result = [Double]()
        
        sut.$opacity
            .dropFirst()
            .sink {
                result.append($0)
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        selection.editMode = .active
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(result, [1.0, 1.0])
    }
    
    func testOpacity_whenAlbumListEditingAndSystemAlbum_shouldReturnRightValue() {
        let selection = AlbumSelection()
        let systemAlbum = AlbumEntity(id: 4, name: "Gif", coverNode: NodeEntity(handle: 3),
                                      count: 1, type: .gif, modificationTime: nil)
        let sut = makeAlbumCellViewModel(album: systemAlbum, selection: selection)
        
        let exp = expectation(description: "Should set shouldShowEditStateOpacity to 0.5")
        exp.expectedFulfillmentCount = 2
        
        var result = [Double]()
        
        sut.$opacity
            .dropFirst()
            .sink {
                result.append($0)
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        selection.editMode = .active
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(result, [1.0, 0.5])
    }
    
    func testOnAlbumTap_onUserAlbum_shouldToggleSelectionAndTrackEvent() {
        [EditMode.active, .transient].forEach { editMode in
            let album = AlbumEntity(id: 4, type: .user)
            let tracker = MockTracker()
            let selection = AlbumSelection()
            selection.editMode = editMode
            let sut = makeAlbumCellViewModel(
                album: album,
                selection: selection,
                tracker: tracker)
            
            XCTAssertFalse(sut.isSelected, "Failed on editMode: \(editMode)")
            
            sut.onAlbumTap()
            
            XCTAssertTrue(sut.isSelected, "Failed on editMode: \(editMode)")
            
            sut.onAlbumTap()
            
            XCTAssertFalse(sut.isSelected, "Failed on editMode: \(editMode)")
            
            assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [
                    album.makeAlbumSelectedEvent(selectionType: .multiadd),
                    album.makeAlbumSelectedEvent(selectionType: .multiremove)
                ]
            )
        }
    }
    
    func testOnAlbumTap_whenUserTap_shouldSetCorrectValues() {
        var selectedAlbum: AlbumEntity?
        let selectedAlbumBinding = Binding(get: {
            selectedAlbum
        }, set: {
            selectedAlbum = $0
        })
        let gifAlbum = AlbumEntity(id: 2, name: "", coverNode: NodeEntity(handle: 1), count: 1, type: .gif)
        let tracker = MockTracker()
        let sut = makeAlbumCellViewModel(
            album: gifAlbum,
            tracker: tracker,
            selectedAlbum: selectedAlbumBinding)
        
        sut.onAlbumTap()
        
        XCTAssertEqual(selectedAlbum, gifAlbum)
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                gifAlbum.makeAlbumSelectedEvent(selectionType: .single)
            ]
        )
    }
    
    func testOnAlbumTap_notInEditMode_shouldSendSelectedEvent() {
        let userAlbum = AlbumEntity(id: 5, type: .user,
                                    metaData: AlbumMetaDataEntity(
                                        imageCount: 6,
                                        videoCount: 8))
        let tracker = MockTracker()
        let selection = AlbumSelection()
        selection.editMode = .inactive
        
        let sut = makeAlbumCellViewModel(
            album: userAlbum,
            selection: selection,
            tracker: tracker)
        
        sut.onAlbumTap()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                userAlbum.makeAlbumSelectedEvent(selectionType: .single)
            ]
        )
    }
    
    func testOnAlbumTap_whenUserTapOnAlbumCellInEditMode_ShouldNotToggleForSystemAlbums() {
        [EditMode.active, .transient].forEach { editMode in
            let selection = AlbumSelection()
            selection.editMode = editMode
            let tracker = MockTracker()
            let sut = makeAlbumCellViewModel(
                album: AlbumEntity(id: 4, name: "Gif", coverNode: NodeEntity(handle: 3),
                                   count: 1, type: .gif, modificationTime: nil),
                selection: selection,
                tracker: tracker)
            
            XCTAssertFalse(sut.isSelected, "Failed on editMode: \(editMode)")
            
            sut.onAlbumTap()
            
            XCTAssertFalse(sut.isSelected, "Failed on editMode: \(editMode)")
            XCTAssertTrue(tracker.trackedEventIdentifiers.isEmpty, "Failed on editMode: \(editMode)")
        }
    }
    
    func testOnAlbumTap_whenUserTapOnAlbumAfterPhotosLoaded_shouldSendCorrectAnalyticsEvent() {
        let albumId = HandleEntity(6554)
        let albumPhotos = [
            AlbumPhotoEntity(photo: NodeEntity(name: "test.jpg", handle: 1),
                             albumPhotoId: albumId),
            AlbumPhotoEntity(photo: NodeEntity(name: "test2.jpg", handle: 2),
                             albumPhotoId: albumId),
            AlbumPhotoEntity(photo: NodeEntity(name: "test2.mp4", handle: 3),
                             albumPhotoId: albumId)
        ]
        let monitorUserAlbumPhotos = SingleItemAsyncSequence(item: albumPhotos)
            .eraseToAnyAsyncSequence()
        let monitorAlbumsUseCase = MockMonitorAlbumsUseCase(monitorUserAlbumPhotosAsyncSequence: monitorUserAlbumPhotos)
        
        let tracker = MockTracker()
        let sut = makeAlbumCellViewModel(
            album: .init(id: albumId, type: .user),
            monitorAlbumsUseCase: monitorAlbumsUseCase,
            tracker: tracker,
            featureFlagProvider: MockFeatureFlagProvider(list: [.albumPhotoCache: true]))
        
        let exp = expectation(description: "Album photos loaded")
        
        let subscription = sut.$numberOfNodes
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }
        
        let cancelledExp = expectation(description: "Task canncelled")
        let task = Task { @MainActor in
            await sut.monitorAlbumPhotos()
            cancelledExp.fulfill()
        }
        
        wait(for: [exp], timeout: 0.2)
        task.cancel()
        wait(for: [cancelledExp], timeout: 0.2)
        
        sut.onAlbumTap()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                AlbumSelectedEvent(
                    selectionType: .single,
                    imageCount: 2,
                    videoCount: 1
                )
            ]
        )
        
        subscription.cancel()
    }
    
    func testFeatureFlagForShowingShareIconOnAlbum_whenTurnedOff_shouldNotShowShareLink() {
        
        let sut = makeAlbumCellViewModel(
            album: AlbumEntity(id: 4, name: "User", coverNode: NodeEntity(handle: 3), count: 1, type: .user, modificationTime: nil, sharedLinkStatus: .exported(true)))
        
        XCTAssertTrue(sut.isLinkShared)
    }
    
    func testMonitorAlbumPhotos_onPhotosReturned_shouldUpdateNodeCount() async {
        for await hiddenNodesFeatureFlag in [true, false].async {
            let albumId = HandleEntity(65)
            let albumPhotos = (1...15).map {
                AlbumPhotoEntity(photo: NodeEntity(handle: $0),
                                 albumPhotoId: albumId)
            }
            let monitorUserAlbumPhotos = SingleItemAsyncSequence(item: albumPhotos)
                .eraseToAnyAsyncSequence()
            let monitorAlbumsUseCase = MockMonitorAlbumsUseCase(monitorUserAlbumPhotosAsyncSequence: monitorUserAlbumPhotos)
            let featureFlagProvider = MockFeatureFlagProvider(list: [.albumPhotoCache: true,
                                                                     .hiddenNodes: hiddenNodesFeatureFlag])
            let album = AlbumEntity(id: albumId, type: .user)
            
            let sut = makeAlbumCellViewModel(album: album,
                                             monitorAlbumsUseCase: monitorAlbumsUseCase,
                                             featureFlagProvider: featureFlagProvider)
            
            let exp = expectation(description: "Should update count")
            
            let subscription = sut.$numberOfNodes
                .dropFirst()
                .sink {
                    XCTAssertEqual($0, albumPhotos.count)
                    exp.fulfill()
                }
            
            let task = Task { await sut.monitorAlbumPhotos() }
            
            await fulfillment(of: [exp], timeout: 1.0)
            task.cancel()
            subscription.cancel()
            
            let monitorTypes = await monitorAlbumsUseCase.state.monitorTypes
            XCTAssertEqual(monitorTypes,
                           [.userAlbumPhotos(excludeSensitives: hiddenNodesFeatureFlag, includeSensitiveInherited: hiddenNodesFeatureFlag)])
        }
    }
    
    func testMonitorAlbumPhotos_userAlbumCoverNil_shouldSetLatestPhotoAsCover() throws {
        let latestCoverHandle = HandleEntity(76)
        let album = AlbumEntity(id: 65, name: "User",
                                coverNode: nil, count: 0, type: .user)
        let thumbnailContainer = ImageContainer(image: Image("folder"), type: .thumbnail)
        let thumbnailAsyncSequence = makeThumbnailAsyncSequence(container: thumbnailContainer)
        let thumbnailLoader = MockThumbnailLoader(loadImages: [latestCoverHandle: thumbnailAsyncSequence])
        
        let albumPhotos = [
            AlbumPhotoEntity(
                photo: NodeEntity(
                    handle: 1,
                    modificationTime: try "2024-05-03T22:01:04Z".date),
                albumPhotoId: album.id),
            AlbumPhotoEntity(
                photo: NodeEntity(
                    handle: latestCoverHandle,
                    modificationTime: try "2024-05-04T10:01:04Z".date),
                albumPhotoId: album.id),
            AlbumPhotoEntity(
                photo: NodeEntity(
                    handle: 5,
                    modificationTime: try "2024-05-02T05:01:04Z".date),
                albumPhotoId: album.id)
        ]
        let monitorUserAlbumPhotos = SingleItemAsyncSequence(item: albumPhotos)
            .eraseToAnyAsyncSequence()
        let monitorAlbumsUseCase = MockMonitorAlbumsUseCase(monitorUserAlbumPhotosAsyncSequence: monitorUserAlbumPhotos)
        
        let featureFlagProvider = MockFeatureFlagProvider(list: [.albumPhotoCache: true])
        
        let sut = makeAlbumCellViewModel(album: album,
                                         thumbnailLoader: thumbnailLoader,
                                         monitorAlbumsUseCase: monitorAlbumsUseCase,
                                         featureFlagProvider: featureFlagProvider)
        
        let exp = expectation(description: "Should update thumbnail with latest photo")
        
        let subscription = thumbnailContainerUpdates(on: sut) {
            XCTAssertTrue($0.isEqual(thumbnailContainer))
            exp.fulfill()
        }
        let cancelled = expectation(description: "Async sequence cancelled")
        let task = Task {
            await sut.monitorAlbumPhotos()
            cancelled.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        task.cancel()
        subscription.cancel()
        wait(for: [cancelled], timeout: 0.5)
    }
    
    func testMonitorAlbumPhotos_userAlbumCoverNilNoPhotos_shouldNotUpdateAlbumCover() async throws {
        let album = AlbumEntity(id: 65, name: "User",
                                coverNode: nil, count: 0, type: .user)
        
        let monitorUserAlbumPhotos = SingleItemAsyncSequence<[AlbumPhotoEntity]>(item: [])
            .eraseToAnyAsyncSequence()
        let monitorAlbumsUseCase = MockMonitorAlbumsUseCase(monitorUserAlbumPhotosAsyncSequence: monitorUserAlbumPhotos)
        let featureFlagProvider = MockFeatureFlagProvider(list: [.albumPhotoCache: true])
        
        let sut = makeAlbumCellViewModel(album: album,
                                         monitorAlbumsUseCase: monitorAlbumsUseCase,
                                         featureFlagProvider: featureFlagProvider)
        
        let exp = expectation(description: "Should not update thumbnail with latest photo")
        exp.isInverted = true
        
        let subscription = thumbnailContainerUpdates(on: sut) { _ in
            exp.fulfill()
        }
        
        let task = Task { await sut.monitorAlbumPhotos() }
        
        await fulfillment(of: [exp], timeout: 0.5)
        task.cancel()
        subscription.cancel()
    }
    
    func testMonitorAlbumPhotos_userAlbumCoverIsInRubbishBin_shouldUseDefaultCover() async {
        let cover = NodeEntity(handle: 54)
        let album = AlbumEntity(id: 65, name: "User",
                                coverNode: cover, count: 0, type: .user)
        let defaultCover = NodeEntity(handle: 87)
        let coverImageContainer = ImageContainer(image: Image("folder"), type: .thumbnail)
        let thumbnailAsyncSequence = makeThumbnailAsyncSequence(container: coverImageContainer)
        let thumbnailLoader = MockThumbnailLoader(loadImages: [defaultCover.handle: thumbnailAsyncSequence])
        
        let monitorUserAlbumPhotos = SingleItemAsyncSequence(item: [
            AlbumPhotoEntity(photo: defaultCover)
        ]).eraseToAnyAsyncSequence()
        let monitorAlbumsUseCase = MockMonitorAlbumsUseCase(
            monitorUserAlbumPhotosAsyncSequence: monitorUserAlbumPhotos)
        let nodeUseCase = MockNodeDataUseCase(isNodeInRubbishBin: { _ in true })
        let featureFlagProvider = MockFeatureFlagProvider(list: [.albumPhotoCache: true])
        
        let sut = makeAlbumCellViewModel(album: album,
                                         thumbnailLoader: thumbnailLoader,
                                         monitorAlbumsUseCase: monitorAlbumsUseCase,
                                         nodeUseCase: nodeUseCase,
                                         featureFlagProvider: featureFlagProvider)
        
        let exp = expectation(description: "Should update cover with default photo")
        
        let subscription = thumbnailContainerUpdates(on: sut) {
            XCTAssertTrue($0.isEqual(coverImageContainer))
            exp.fulfill()
        }
        
        let task = Task { await sut.monitorAlbumPhotos() }
        
        await fulfillment(of: [exp], timeout: 1.0)
        task.cancel()
        subscription.cancel()
    }
    
    func testMonitorAlbumPhotos_userAlbumCoverIsRestoredFromRubbish_shouldSetAlbumCover() async {
        let cover = NodeEntity(handle: 54)
        let album = AlbumEntity(id: 65, name: "User",
                                coverNode: cover, count: 0, type: .user)
        let coverImageContainer = ImageContainer(image: Image("folder"), type: .thumbnail)
        let thumbnailAsyncSequence = makeThumbnailAsyncSequence(container: coverImageContainer)
        let thumbnailLoader = MockThumbnailLoader(loadImages: [cover.handle: thumbnailAsyncSequence])
        
        let monitorUserAlbumPhotos = SingleItemAsyncSequence(item: [
            AlbumPhotoEntity(photo: cover)
        ]).eraseToAnyAsyncSequence()
        let monitorAlbumsUseCase = MockMonitorAlbumsUseCase(
            monitorUserAlbumPhotosAsyncSequence: monitorUserAlbumPhotos)
        let nodeUseCase = MockNodeDataUseCase(isNodeInRubbishBin: { _ in false })
        let featureFlagProvider = MockFeatureFlagProvider(list: [.albumPhotoCache: true])
        
        let sut = makeAlbumCellViewModel(album: album,
                                         thumbnailLoader: thumbnailLoader,
                                         monitorAlbumsUseCase: monitorAlbumsUseCase,
                                         nodeUseCase: nodeUseCase,
                                         featureFlagProvider: featureFlagProvider)
        
        let loadedThumbnail = ImageContainer(image: Image(systemName: "heart"), type: .thumbnail)
        sut.thumbnailContainer = loadedThumbnail
        
        let exp = expectation(description: "Should update cover with album cover photo")
        
        let subscription = thumbnailContainerUpdates(on: sut) {
            XCTAssertTrue($0.isEqual(coverImageContainer))
            exp.fulfill()
        }
        
        let task = Task { await sut.monitorAlbumPhotos() }
        
        await fulfillment(of: [exp], timeout: 1.0)
        task.cancel()
        subscription.cancel()
    }
    
    func testMonitorAlbumPhotos_userAlbumCoverNotInRubbishButNotInPhotos_shouldUseDefaultCover() async {
        let cover = NodeEntity(handle: 54)
        let album = AlbumEntity(id: 65, name: "User",
                                coverNode: cover, count: 0, type: .user)
        let defaultCover = NodeEntity(handle: 87)
        let coverImageContainer = ImageContainer(image: Image("folder"), type: .thumbnail)
        let thumbnailAsyncSequence = makeThumbnailAsyncSequence(container: coverImageContainer)
        let thumbnailLoader = MockThumbnailLoader(loadImages: [defaultCover.handle: thumbnailAsyncSequence])
        
        let monitorUserAlbumPhotos = SingleItemAsyncSequence(item: [
            AlbumPhotoEntity(photo: defaultCover)
        ]).eraseToAnyAsyncSequence()
        let monitorAlbumsUseCase = MockMonitorAlbumsUseCase(
            monitorUserAlbumPhotosAsyncSequence: monitorUserAlbumPhotos)
        let nodeUseCase = MockNodeDataUseCase(isNodeInRubbishBin: { _ in false })
        let featureFlagProvider = MockFeatureFlagProvider(list: [.albumPhotoCache: true])
        
        let sut = makeAlbumCellViewModel(album: album,
                                         thumbnailLoader: thumbnailLoader,
                                         monitorAlbumsUseCase: monitorAlbumsUseCase,
                                         nodeUseCase: nodeUseCase,
                                         featureFlagProvider: featureFlagProvider)
        
        let exp = expectation(description: "Should update cover with default photo")
        
        let subscription = thumbnailContainerUpdates(on: sut) {
            XCTAssertTrue($0.isEqual(coverImageContainer))
            exp.fulfill()
        }
        
        let task = Task { await sut.monitorAlbumPhotos() }
        
        await fulfillment(of: [exp], timeout: 1.0)
        task.cancel()
        subscription.cancel()
    }
    
    func testMonitorAlbumPhotos_coverSetThenPhotosRemoved_shouldSetToPlaceholder() async {
        let album = AlbumEntity(id: 65, name: "User",
                                coverNode: nil, count: 0, type: .user)
        let monitorAlbumsUseCase = MockMonitorAlbumsUseCase(
            monitorUserAlbumPhotosAsyncSequence: SingleItemAsyncSequence(item: []).eraseToAnyAsyncSequence())
        
        let featureFlagProvider = MockFeatureFlagProvider(list: [.albumPhotoCache: true])
        
        let sut = makeAlbumCellViewModel(album: album,
                                         monitorAlbumsUseCase: monitorAlbumsUseCase,
                                         featureFlagProvider: featureFlagProvider)
        sut.thumbnailContainer = ImageContainer(image: Image("folder"), type: .thumbnail)
        
        let exp = expectation(description: "Should update cover with placeholder")
        
        let subscription = thumbnailContainerUpdates(on: sut) {
            XCTAssertTrue($0.type == .placeholder)
            exp.fulfill()
        }
        
        let task = Task { await sut.monitorAlbumPhotos() }
        
        await fulfillment(of: [exp], timeout: 1.0)
        task.cancel()
        subscription.cancel()
    }
    
    func testMonitorCoverPhotoSensitivity_coverMarkedAsSensitive_shouldNotUpdateImageContainerOnInheritSensitivityChange() {
        let cover = NodeEntity(handle: 65, isMarkedSensitive: true)
        let album = AlbumEntity(id: 45, coverNode: cover, type: .user)
        let coverImageContainer = ImageContainer(image: Image("folder"), type: .thumbnail)
        let sut = makeAlbumCellViewModel(
            album: album,
            thumbnailLoader: MockThumbnailLoader(initialImage: coverImageContainer),
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(
                isInheritingSensitivityResult: .success(true)),
            featureFlagProvider: MockFeatureFlagProvider(list: [.hiddenNodes: true])
        )
        
        let exp = expectation(description: "Should not update thumbnail container")
        exp.isInverted = true
        
        let subscription = thumbnailContainerUpdates(on: sut) { _ in
            exp.fulfill()
        }
        trackTaskCancellation { await sut.monitorCoverPhotoSensitivity() }
    
        wait(for: [exp], timeout: 0.5)
    }
    
    func testMonitorCoverPhotoSensitivity_withAlbumCoverSensitivityUpdate_shouldUpdateImageContainerWithInitialResultThenMonitorUpdates() async throws {
        let cover = NodeEntity(handle: 65)
        let album = AlbumEntity(id: 45, coverNode: cover, type: .user)
        let coverImageContainer = ImageContainer(image: Image("folder"), type: .thumbnail)
        let isInheritedSensitivity = false
        let isInheritedSensitivityUpdate = true
        let monitorInheritedSensitivityForNode = SingleItemAsyncSequence(item: isInheritedSensitivityUpdate)
            .eraseToAnyAsyncThrowingSequence()
        let sensitiveNodeUseCase = MockSensitiveNodeUseCase(
            isInheritingSensitivityResult: .success(isInheritedSensitivity),
            monitorInheritedSensitivityForNode: monitorInheritedSensitivityForNode)
        let sut = makeAlbumCellViewModel(
            album: album,
            thumbnailLoader: MockThumbnailLoader(initialImage: coverImageContainer),
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            featureFlagProvider: MockFeatureFlagProvider(list: [.hiddenNodes: true])
        )
        
        var expectedImageContainer = [
            coverImageContainer.toSensitiveImageContaining(isSensitive: isInheritedSensitivity),
            coverImageContainer.toSensitiveImageContaining(isSensitive: isInheritedSensitivityUpdate)
        ]
        
        let exp = expectation(description: "Should update cover with initial then from monitor")
        exp.expectedFulfillmentCount = expectedImageContainer.count
        
        let subscription = thumbnailContainerUpdates(on: sut) {
            XCTAssertTrue($0.isEqual(expectedImageContainer.removeFirst()))
            exp.fulfill()
        }
        
        let cancelledExp = expectation(description: "cancelled")
        let task = Task {
            await sut.monitorCoverPhotoSensitivity()
            cancelledExp.fulfill()
        }
        
        await fulfillment(of: [exp], timeout: 1.0)
        task.cancel()
        await fulfillment(of: [cancelledExp], timeout: 0.5)
        subscription.cancel()
    }
    
    func testMonitorCoverPhotoSensitivity_albumCoverSensitiveChange_shouldNotUpdateCoverIfContainerTheSame() async throws {
        let cover = NodeEntity(handle: 65, isMarkedSensitive: false)
        let album = AlbumEntity(id: 45, coverNode: cover, type: .user)
        let isInheritedSensitivityUpdate = false
        let imageContainer = SensitiveImageContainer(image: Image("folder"), type: .thumbnail, isSensitive: cover.isMarkedSensitive)
        
        let monitorInheritedSensitivityForNode = SingleItemAsyncSequence(item: isInheritedSensitivityUpdate)
            .eraseToAnyAsyncThrowingSequence()
        let sensitiveNodeUseCase = MockSensitiveNodeUseCase(
            monitorInheritedSensitivityForNode: monitorInheritedSensitivityForNode)
        let sut = makeAlbumCellViewModel(
            album: album,
            thumbnailLoader: MockThumbnailLoader(initialImage: imageContainer),
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            featureFlagProvider: MockFeatureFlagProvider(list: [.hiddenNodes: true])
        )
        
        let exp = expectation(description: "Should note update album cover")
        exp.isInverted = true
        
        let subscription = thumbnailContainerUpdates(on: sut) { _ in
            exp.fulfill()
        }
        
        let cancelledExp = expectation(description: "cancelled")
        let task = Task {
            await sut.monitorCoverPhotoSensitivity()
            cancelledExp.fulfill()
        }
        
        await fulfillment(of: [exp], timeout: 1.0)
        task.cancel()
        await fulfillment(of: [cancelledExp], timeout: 0.5)
        subscription.cancel()
    }
    
    func testMonitorCoverPhotoSensitivity_thumbnailContainerPlaceholder_shouldNotUpdateImageContainerWithInheritedChanges() async throws {
        let cover = NodeEntity(handle: 65, isMarkedSensitive: false)
        let album = AlbumEntity(id: 45, coverNode: cover, type: .user)
        let imageContainer = ImageContainer(image: Image("folder"), type: .placeholder)
        
        let monitorInheritedSensitivityForNode = SingleItemAsyncSequence(item: !cover.isMarkedSensitive)
            .eraseToAnyAsyncThrowingSequence()
        let sensitiveNodeUseCase = MockSensitiveNodeUseCase(
            monitorInheritedSensitivityForNode: monitorInheritedSensitivityForNode)
        
        let sut = makeAlbumCellViewModel(
            album: album,
            thumbnailLoader: MockThumbnailLoader(initialImage: imageContainer),
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            featureFlagProvider: MockFeatureFlagProvider(list: [.hiddenNodes: true])
        )
        
        let exp = expectation(description: "Should not update image container")
        exp.isInverted = true
        
        let subscription = thumbnailContainerUpdates(on: sut) { _ in
            exp.fulfill()
        }
        let cancelledExp = expectation(description: "cancelled")
        let task = Task {
            await sut.monitorCoverPhotoSensitivity()
            cancelledExp.fulfill()
        }
        
        await fulfillment(of: [exp], timeout: 1.0)
        task.cancel()
        await fulfillment(of: [cancelledExp], timeout: 0.5)
        subscription.cancel()
    }
    
    // MARK: - Helpers
    
    private func makeAlbumCellViewModel(
        album: AlbumEntity,
        thumbnailLoader: some ThumbnailLoaderProtocol = MockThumbnailLoader(),
        monitorAlbumsUseCase: some MonitorAlbumsUseCaseProtocol = MockMonitorAlbumsUseCase(),
        nodeUseCase: some NodeUseCaseProtocol = MockNodeDataUseCase(),
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol = MockSensitiveNodeUseCase(),
        contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol = MockContentConsumptionUserAttributeUseCase(),
        selection: AlbumSelection = AlbumSelection(),
        tracker: some AnalyticsTracking = MockTracker(),
        selectedAlbum: Binding<AlbumEntity?> = .constant(nil),
        featureFlagProvider: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [:]),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> AlbumCellViewModel {
        let sut = AlbumCellViewModel(thumbnailLoader: thumbnailLoader,
                                     monitorAlbumsUseCase: monitorAlbumsUseCase,
                                     nodeUseCase: nodeUseCase,
                                     sensitiveNodeUseCase: sensitiveNodeUseCase,
                                     contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase,
                                     album: album,
                                     selection: selection,
                                     tracker: tracker,
                                     selectedAlbum: selectedAlbum,
                                     featureFlagProvider: featureFlagProvider)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
    
    private func makeThumbnailAsyncSequence(
        container: ImageContainer = ImageContainer(image: Image("folder"), type: .thumbnail)
    ) -> AnyAsyncSequence<any ImageContaining> {
        SingleItemAsyncSequence(item: container)
            .eraseToAnyAsyncSequence()
    }
    
    private func thumbnailContainerUpdates(on sut: AlbumCellViewModel, action: @escaping (any ImageContaining) -> Void) -> AnyCancellable {
        sut.$thumbnailContainer
            .dropFirst()
            .sink(receiveValue: action)
    }
}
