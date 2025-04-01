import Combine
@testable import ContentLibraries
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGAAssets
import MEGADomain
import MEGADomainMock
import MEGASwift
import MEGASwiftUI
import MEGATest
import SwiftUI
import Testing
import XCTest

final class AlbumCellViewModelTests: XCTestCase {
    private let album = AlbumEntity(id: 1, name: "Test", coverNode: NodeEntity(handle: 1), count: 15, type: .favourite)
    private var subscriptions = Set<AnyCancellable>()
    
    @MainActor
    func testInit_setTitleNodesAndTitlePublishers() throws {
        let sut = makeAlbumCellViewModel(album: album)
        
        XCTAssertEqual(sut.title, AttributedString(album.name))
        XCTAssertEqual(sut.numberOfNodes, album.count)
        XCTAssertTrue(sut.thumbnailContainer.type == .placeholder)
        XCTAssertFalse(sut.isLoading)
    }
    
    @MainActor
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
    
    @MainActor
    func testLoadAlbumThumbnail_onLoadThumbnail_thumbnailContainerIsUpdatedWithLoadedImageIfContainerIsCurrentlyPlaceholder() async throws {
        let thumbnailContainer = ImageContainer(image: Image("folder"), type: .thumbnail)
        let thumbnailLoader = MockThumbnailLoader(loadImage: makeThumbnailAsyncSequence(container: thumbnailContainer))
        let sut = makeAlbumCellViewModel(album: album,
                                         thumbnailLoader: thumbnailLoader)
        
        await sut.loadAlbumThumbnail()
        
        XCTAssertTrue(sut.thumbnailContainer.isEqual(thumbnailContainer))
    }
    
    @MainActor
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
    
    @MainActor
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
    
    @MainActor
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
    
    @MainActor
    func testIsSelected_whenUserTapOnAlbum_shouldBeSelected() {
        let userAlbum = AlbumEntity(id: 1, type: .user)
        for (album, isSelected) in [(userAlbum, true),
                                    (album, false)] {
            let selection = AlbumSelection()
            let sut = makeAlbumCellViewModel(album: album,
                                             selection: selection)
            selection.editMode = .active
            
            sut.onAlbumTap()
            
            XCTAssertEqual(selection.isAlbumSelected(album), isSelected)
        }
    }
    
    @MainActor
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
    
    @MainActor
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
    
    @MainActor
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
    
    @MainActor
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
    
    @MainActor
    func testOnAlbumTap_onUserAlbum_shouldToggleSelectionAndTrackEvent() async {
        for editMode in [EditMode.active, .transient] {
            let album = AlbumEntity(id: 4, type: .user)
            let tracker = MockTracker()
            let selection = AlbumSelection()
            selection.editMode = editMode
            let sut = makeAlbumCellViewModel(
                album: album,
                selection: selection,
                tracker: tracker,
                onAlbumSelected: {_ in })
            
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
    
    @MainActor
    func testOnAlbumTap_whenUserTap_shouldSetCorrectValues() async {
        let gifAlbum = AlbumEntity(id: 2, name: "", coverNode: NodeEntity(handle: 1), count: 1, type: .gif)
        let tracker = MockTracker()
        let sut = makeAlbumCellViewModel(
            album: gifAlbum,
            tracker: tracker,
            onAlbumSelected: {
                XCTAssertEqual($0, gifAlbum)
            })
        
        sut.onAlbumTap()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                gifAlbum.makeAlbumSelectedEvent(selectionType: .single)
            ]
        )
    }
    
    @MainActor
    func testOnAlbumTap_notInEditMode_shouldSendSelectedEvent() async {
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
    
    @MainActor
    func testOnAlbumTap_whenUserTapOnAlbumCellInEditMode_ShouldNotToggleForSystemAlbums() async {
        for editMode in [EditMode.active, .transient] {
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
    
    @MainActor
    func testOnAlbumTap_whenUserTapOnAlbumAfterPhotosLoaded_shouldSendCorrectAnalyticsEvent() async {
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
        let monitorUserAlbumPhotosUseCase = MockMonitorUserAlbumPhotosUseCase(
            monitorUserAlbumPhotosAsyncSequence: monitorUserAlbumPhotos)
        
        let tracker = MockTracker()
        let sut = makeAlbumCellViewModel(
            album: .init(id: albumId, type: .user),
            monitorUserAlbumPhotosUseCase: monitorUserAlbumPhotosUseCase,
            tracker: tracker,
            configuration: .mockConfiguration(isAlbumPerformanceImprovementsEnabled: true)
        )
        
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
        
        await fulfillment(of: [exp], timeout: 0.2)
        task.cancel()
        await fulfillment(of: [cancelledExp], timeout: 0.2)
        
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
    
    @MainActor
    func testFeatureFlagForShowingShareIconOnAlbum_whenTurnedOff_shouldNotShowShareLink() {
        
        let sut = makeAlbumCellViewModel(
            album: AlbumEntity(id: 4, name: "User", coverNode: NodeEntity(handle: 3), count: 1, type: .user, modificationTime: nil, sharedLinkStatus: .exported(true)))
        
        XCTAssertTrue(sut.isLinkShared)
    }
    
    @MainActor
    func testMonitorAlbumPhotos_onPhotosReturned_shouldUpdateNodeCount() async {
        for await excludeSensitives in [true, false].async {
            let albumId = HandleEntity(65)
            let albumPhotos = (1...15).map {
                AlbumPhotoEntity(photo: NodeEntity(handle: $0),
                                 albumPhotoId: albumId)
            }
            let monitorUserAlbumPhotos = SingleItemAsyncSequence(item: albumPhotos)
                .eraseToAnyAsyncSequence()
            let monitorUserAlbumPhotosUseCase = MockMonitorUserAlbumPhotosUseCase(
                monitorUserAlbumPhotosAsyncSequence: monitorUserAlbumPhotos)
            let album = AlbumEntity(id: albumId, type: .user)
            
            let sut = makeAlbumCellViewModel(album: album,
                                             monitorUserAlbumPhotosUseCase: monitorUserAlbumPhotosUseCase,
                                             sensitiveDisplayPreferenceUseCase: MockSensitiveDisplayPreferenceUseCase(
                                                excludeSensitives: excludeSensitives),
                                             configuration: .mockConfiguration(isAlbumPerformanceImprovementsEnabled: true)
            )
            
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
            
            XCTAssertEqual(monitorUserAlbumPhotosUseCase.invocations,
                           [.userAlbumPhotos(excludeSensitives: excludeSensitives)])
        }
    }
    
    @MainActor
    func testMonitorAlbumPhotos_albumCoverRetrieved_shouldSetThumbnail() {
        let album = AlbumEntity(id: 65, coverNode: nil, type: .user)
        let coverNode = NodeEntity(handle: 1)
        let albumPhotos = [
            AlbumPhotoEntity(
                photo: coverNode,
                albumPhotoId: album.id)
        ]
        let thumbnailContainer = ImageContainer(image: Image("folder"), type: .thumbnail)
        let thumbnailAsyncSequence = makeThumbnailAsyncSequence(container: thumbnailContainer)
        let thumbnailLoader = MockThumbnailLoader(loadImages: [coverNode.handle: thumbnailAsyncSequence])
        let monitorUserAlbumPhotos = SingleItemAsyncSequence(item: albumPhotos)
            .eraseToAnyAsyncSequence()
        let monitorUserAlbumPhotosUseCase = MockMonitorUserAlbumPhotosUseCase(
            monitorUserAlbumPhotosAsyncSequence: monitorUserAlbumPhotos)
        let albumCoverUseCase = MockAlbumCoverUseCase(albumCover: coverNode)
        
        let sut = makeAlbumCellViewModel(
            album: album,
            thumbnailLoader: thumbnailLoader,
            monitorUserAlbumPhotosUseCase: monitorUserAlbumPhotosUseCase,
            albumCoverUseCase: albumCoverUseCase,
            configuration: .mockConfiguration(isAlbumPerformanceImprovementsEnabled: true)
        )
        let exp = expectation(description: "Should update thumbnail with latest photo")
        
        let subscription = thumbnailContainerUpdates(on: sut) {
            XCTAssertTrue($0.isEqual(thumbnailContainer))
            exp.fulfill()
        }
        trackTaskCancellation { await sut.monitorAlbumPhotos() }
        
        wait(for: [exp], timeout: 1.0)
        subscription.cancel()
    }
    
    @MainActor
    func testMonitorAlbumPhotos_retrievedUserAlbumCoverNil_shouldSetPlaceholder() throws {
        let initialCover = NodeEntity(handle: 3)
        let album = AlbumEntity(id: 65, name: "User",
                                coverNode: initialCover, count: 0, type: .user)
        let thumbnailContainer = ImageContainer(image: Image("folder"), type: .thumbnail)
        let thumbnailLoader = MockThumbnailLoader(initialImage: thumbnailContainer)
        
        let monitorUserAlbumPhotosUseCase = MockMonitorUserAlbumPhotosUseCase(
            monitorUserAlbumPhotosAsyncSequence: SingleItemAsyncSequence(item: []).eraseToAnyAsyncSequence())
        let albumCoverUseCase = MockAlbumCoverUseCase(albumCover: nil)
        
        let sut = makeAlbumCellViewModel(album: album,
                                         thumbnailLoader: thumbnailLoader,
                                         monitorUserAlbumPhotosUseCase: monitorUserAlbumPhotosUseCase,
                                         albumCoverUseCase: albumCoverUseCase,
                                         configuration: .mockConfiguration(isAlbumPerformanceImprovementsEnabled: true)
        )
        
        let exp = expectation(description: "Should update thumbnail with latest photo")
        
        let subscription = thumbnailContainerUpdates(on: sut) {
            XCTAssertTrue($0.type == .placeholder)
            exp.fulfill()
        }
        trackTaskCancellation { await sut.monitorAlbumPhotos() }
        
        wait(for: [exp], timeout: 1.0)
        subscription.cancel()
    }
    
    @MainActor
    func testMonitorAlbumPhotos_userAlbumCoverNilNoPhotos_shouldNotUpdateAlbumCover() async throws {
        let album = AlbumEntity(id: 65, name: "User",
                                coverNode: nil, count: 0, type: .user)
        
        let monitorUserAlbumPhotos = SingleItemAsyncSequence<[AlbumPhotoEntity]>(item: [])
            .eraseToAnyAsyncSequence()
        let monitorUserAlbumPhotosUseCase = MockMonitorUserAlbumPhotosUseCase(
            monitorUserAlbumPhotosAsyncSequence: monitorUserAlbumPhotos)
        
        let sut = makeAlbumCellViewModel(album: album,
                                         monitorUserAlbumPhotosUseCase: monitorUserAlbumPhotosUseCase,
                                         configuration: .mockConfiguration(isAlbumPerformanceImprovementsEnabled: true)
        )
        
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
    
    @MainActor
    func testMonitorAlbumPhotos_coverSetThenPhotosRemoved_shouldSetToPlaceholder() async {
        let album = AlbumEntity(id: 65, name: "User",
                                coverNode: nil, count: 0, type: .user)
        let monitorUserAlbumPhotosUseCase = MockMonitorUserAlbumPhotosUseCase(
            monitorUserAlbumPhotosAsyncSequence: SingleItemAsyncSequence(item: []).eraseToAnyAsyncSequence())
        
        let sut = makeAlbumCellViewModel(album: album,
                                         monitorUserAlbumPhotosUseCase: monitorUserAlbumPhotosUseCase,
                                         configuration: .mockConfiguration(isAlbumPerformanceImprovementsEnabled: true)
        )
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
    
    @MainActor
    func testMonitorCoverPhotoSensitivity_coverMarkedAsSensitive_shouldNotUpdateImageContainerOnInheritSensitivityChange() {
        let cover = NodeEntity(handle: 65, isMarkedSensitive: true)
        let album = AlbumEntity(id: 45, coverNode: cover, type: .user)
        let coverImageContainer = ImageContainer(image: Image("folder"), type: .thumbnail)
        let sut = makeAlbumCellViewModel(
            album: album,
            thumbnailLoader: MockThumbnailLoader(initialImage: coverImageContainer),
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(
                isInheritingSensitivityResult: .success(true)),
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true])
        )
        
        let exp = expectation(description: "Should not update thumbnail container")
        exp.isInverted = true
        
        let subscription = thumbnailContainerUpdates(on: sut) { _ in
            exp.fulfill()
        }
        trackTaskCancellation { await sut.monitorCoverPhotoSensitivity() }
        
        wait(for: [exp], timeout: 0.5)
        subscription.cancel()
    }
    
    @MainActor
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
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true])
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
    
    @MainActor
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
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true])
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
    
    @MainActor
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
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true])
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
    
    @MainActor
    func testIsGestureEnabled_onTappedProvided_shouldEnable() {
        let testCases: [(((AlbumEntity) -> Void)?, Bool)] = [
            (nil, false),
            ({ _ in }, true)
        ]
        
        for (onAlbumSelected, isEnabled) in testCases {
            let sut = makeAlbumCellViewModel(
                album: album,
                onAlbumSelected: onAlbumSelected
            )
            XCTAssertEqual(sut.isOnTapGestureEnabled, isEnabled)
        }
    }
    
    @MainActor
    func testIsDisabled_singleSelection_shouldUpdateDisabledStatus() {
        let selection = AlbumSelection(mode: .single)
        let album = AlbumEntity(id: 5, type: .user)
        let sut = makeAlbumCellViewModel(
            album: album,
            selection: selection)
        
        var expectedValues = [false, true]
        let exp = expectation(description: "Should update disabled state")
        exp.expectedFulfillmentCount = expectedValues.count
        let cancellable = sut.$isDisabled
            .dropFirst()
            .sink {
                XCTAssertEqual($0, expectedValues.removeFirst())
                exp.fulfill()
            }
        
        selection.setSelectedAlbums([.init(id: 1, type: .user)])
        
        wait(for: [exp], timeout: 0.5)
        cancellable.cancel()
    }
    
    // MARK: - Helpers
    
    @MainActor
    private func makeAlbumCellViewModel(
        album: AlbumEntity,
        thumbnailLoader: some ThumbnailLoaderProtocol = MockThumbnailLoader(),
        monitorUserAlbumPhotosUseCase: some MonitorUserAlbumPhotosUseCaseProtocol = MockMonitorUserAlbumPhotosUseCase(),
        nodeUseCase: some NodeUseCaseProtocol = MockNodeDataUseCase(),
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol = MockSensitiveNodeUseCase(),
        sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol = MockSensitiveDisplayPreferenceUseCase(),
        albumCoverUseCase: some AlbumCoverUseCaseProtocol = MockAlbumCoverUseCase(),
        selection: AlbumSelection = AlbumSelection(),
        tracker: some AnalyticsTracking = MockTracker(),
        onAlbumSelected: ((AlbumEntity) -> Void)? = nil,
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = MockRemoteFeatureFlagUseCase(),
        configuration: ContentLibraries.Configuration = .mockConfiguration(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> AlbumCellViewModel {
        let sut = AlbumCellViewModel(thumbnailLoader: thumbnailLoader,
                                     monitorUserAlbumPhotosUseCase: monitorUserAlbumPhotosUseCase,
                                     nodeUseCase: nodeUseCase,
                                     sensitiveNodeUseCase: sensitiveNodeUseCase,
                                     sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
                                     albumCoverUseCase: albumCoverUseCase,
                                     album: album,
                                     selection: selection,
                                     tracker: tracker,
                                     onAlbumSelected: onAlbumSelected,
                                     remoteFeatureFlagUseCase: remoteFeatureFlagUseCase,
                                     configuration: configuration)
        trackForMemoryLeaks(on: sut, timeoutNanoseconds: 500_000_000, file: file, line: line)
        return sut
    }
    
    private func makeThumbnailAsyncSequence(
        container: ImageContainer = ImageContainer(image: Image("folder"), type: .thumbnail)
    ) -> AnyAsyncSequence<any ImageContaining> {
        SingleItemAsyncSequence(item: container)
            .eraseToAnyAsyncSequence()
    }
    
    @MainActor
    private func thumbnailContainerUpdates(on sut: AlbumCellViewModel, action: @escaping (any ImageContaining) -> Void) -> AnyCancellable {
        sut.$thumbnailContainer
            .dropFirst()
            .sink(receiveValue: action)
    }
}

@Suite("AlbumCellViewModel Tests")
struct AlbumCellViewModelTestSuite {
    
    @Suite("Thumbnail")
    @MainActor
    struct Thumbnail {
        @Test("when album has no cover it should set correct placeholder")
        func noCoverPlaceholder() {
            let sut = makeSUT(
                album: .init(id: 8, type: .user))
            
            #expect(sut.thumbnailContainer.isEqual(ImageContainer(image: MEGAAssetsImageProvider.image(named: .timeline), type: .placeholder)))
        }
        
        @Test("when image container is placeholder it should return true",
              arguments: [(Optional<NodeEntity>.none, true),
                          (NodeEntity(handle: 1), false)])
        func isPlaceholder(coverNode: NodeEntity?, isPlaceholder: Bool) {
            let sut = makeSUT(
                album: .init(id: 8, coverNode: coverNode, type: .user),
                thumbnailLoader: MockThumbnailLoader(
                    initialImage: ImageContainer(
                        image: Image("folder"),
                        type: .thumbnail)))
            
            #expect(sut.isPlaceholder == isPlaceholder)
        }
    }
    
    @Suite("Album link shared")
    @MainActor
    struct LinkShared {
        @Test("when link is shared and not placeholder it should show gradient",
              arguments: [(Optional<NodeEntity>.none, true, false),
                          (Optional<NodeEntity>.none, false, false),
                          (NodeEntity(handle: 1), false, false),
                          (NodeEntity(handle: 1), true, true)])
        func showGradient(coverNode: NodeEntity?, isLinkShared: Bool, showGradient: Bool) {
            let sut = makeSUT(
                album: .init(id: 8, coverNode: coverNode,
                             type: .user, sharedLinkStatus: .exported(isLinkShared)),
                thumbnailLoader: MockThumbnailLoader(
                    initialImage: ImageContainer(
                        image: Image("folder"),
                        type: .thumbnail)))
            
            #expect(sut.shouldShowGradient == showGradient)
        }
    }
    
    @MainActor
    private static func makeSUT(
        album: AlbumEntity,
        thumbnailLoader: some ThumbnailLoaderProtocol = MockThumbnailLoader(),
        monitorUserAlbumPhotosUseCase: some MonitorUserAlbumPhotosUseCaseProtocol = MockMonitorUserAlbumPhotosUseCase(),
        nodeUseCase: some NodeUseCaseProtocol = MockNodeDataUseCase(),
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol = MockSensitiveNodeUseCase(),
        sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol = MockSensitiveDisplayPreferenceUseCase(),
        albumCoverUseCase: some AlbumCoverUseCaseProtocol = MockAlbumCoverUseCase(),
        selection: AlbumSelection = AlbumSelection(),
        tracker: some AnalyticsTracking = MockTracker(),
        onAlbumSelected: ((AlbumEntity) -> Void)? = nil,
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = MockRemoteFeatureFlagUseCase(),
        configuration: ContentLibraries.Configuration = .mockConfiguration()
    ) -> AlbumCellViewModel {
        .init(thumbnailLoader: thumbnailLoader,
              monitorUserAlbumPhotosUseCase: monitorUserAlbumPhotosUseCase,
              nodeUseCase: nodeUseCase,
              sensitiveNodeUseCase: sensitiveNodeUseCase,
              sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
              albumCoverUseCase: albumCoverUseCase,
              album: album,
              selection: selection,
              tracker: tracker,
              onAlbumSelected: onAlbumSelected,
              remoteFeatureFlagUseCase: remoteFeatureFlagUseCase,
              configuration: configuration)
    }
}
