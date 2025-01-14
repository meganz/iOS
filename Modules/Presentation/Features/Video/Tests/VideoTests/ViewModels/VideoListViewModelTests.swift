@preconcurrency import Combine
import MEGADomain
import MEGADomainMock
import MEGAPresentationMock
import MEGATest
@preconcurrency @testable import Video
import XCTest

final class VideoListViewModelTests: XCTestCase {
        
    @MainActor
    func testInit_whenInit_doesNotExecuteSearchOnUseCase() async {
        let (_, _, photoLibraryUseCase, _) = makeSUT()
        
        let messages = await photoLibraryUseCase.messages
        XCTAssertTrue(messages.isEmpty, "Expect to not search on creation")
    }
    
    @MainActor
    func testInit_whenInit_doNotListenToNodesUpdate() {
        let (_, fileSearchUseCase, _, _) = makeSUT()
        
        XCTAssertTrue(fileSearchUseCase.messages.isEmpty, "Expect to not listen nodes update")
    }
    
    // MARK: - init.monitorSortOrderChanged
    
    @MainActor
    func testMonitorSortOrderChanged_whenHasNoSortOrderChanged_doesNotReloadVideos() async {
        // Arrange
        let (sut, _, photoLibraryUseCase, syncModel) = makeSUT()
        var subscriptions = Set<AnyCancellable>()
        let sortOrderExp = expectation(description: "sort order changed")
        sortOrderExp.isInverted = true
        syncModel.$videoRevampSortOrderType
            .dropFirst()
            .sink { _ in
                sortOrderExp.fulfill()
            }
            .store(in: &subscriptions)

        let messagesExp = expectation(description: "spy expectation")
        var receivedMessages: [MockPhotoLibraryUseCase.Message] = []
        messagesExp.assertForOverFulfill = false
        await photoLibraryUseCase.$messages
            .receive(on: DispatchQueue.main)
            .filter { !$0.isEmpty }
            .sink { messages in
                receivedMessages = messages
                messagesExp.fulfill()
            }
            .store(in: &subscriptions)
        
        // Act
        trackTaskCancellation { await sut.onViewAppear() }
        
        await fulfillment(of: [sortOrderExp, messagesExp], timeout: 0.5)
        
        // Assert
        XCTAssertEqual(receivedMessages, [.media])
        
        subscriptions = []
    }
    
    @MainActor
    func testMonitorSortOrderChanged_whenHasSortOrderChanged_reloadVideos() async throws {
        // Arrange
        let (sut, _, photoLibraryUseCase, syncModel) = makeSUT(photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: [], succesfullyLoadMedia: true))

        let onViewAppearTaskStarted = expectation(description: "onViewAppear task started")
        trackTaskCancellation { @MainActor in 
            onViewAppearTaskStarted.fulfill()
            await sut.onViewAppear()
        }
        await fulfillment(of: [onViewAppearTaskStarted], timeout: 0.5)
        
        let sortOrderExp = expectation(description: "Expected favouriteAsc and labelDesc sort order change events")
        
        var subscriptions = Set<AnyCancellable>()
        syncModel.$videoRevampSortOrderType
            .compactMap { $0 }
            .sink { _ in
                sortOrderExp.fulfill()
            }
            .store(in: &subscriptions)
        
        let messagesExp = expectation(description: "spy expectation")
        messagesExp.expectedFulfillmentCount = 2
        var receivedMessages: [MockPhotoLibraryUseCase.Message]?
        await photoLibraryUseCase.$messages
            .receive(on: DispatchQueue.main)
            .filter {
                return !$0.isEmpty
            }
            .sink { messages in
                receivedMessages = messages
                messagesExp.fulfill()
            }
            .store(in: &subscriptions)
        
        // Act
        syncModel.videoRevampSortOrderType = .labelDesc
    
        // Assert
        await fulfillment(of: [sortOrderExp, messagesExp], timeout: 1)
        
        XCTAssertEqual(receivedMessages, [.media, .media])
        subscriptions = []
    }
    
    // MARK: - init.subscribeToEditingMode
    @MainActor
    func testInit_initialState_shouldShowFilterChip() async {
        let (sut, _, _, _) = makeSUT()
        let exp = expectation(description: "show filter chip")
        exp.assertForOverFulfill = false
        var receivedValue = true
        let cancellable = sut.$shouldShowFilterChip
            .sink { shouldShowFilterChip in
                receivedValue = shouldShowFilterChip
                exp.fulfill()
            }
        
        await fulfillment(of: [exp], timeout: 0.5)
        
        XCTAssertTrue(receivedValue)
        cancellable.cancel()
    }
    
    @MainActor
    func testInit_whenIsNotEditing_shouldShowFilterChip() async {
        let (sut, _, _, syncModel) = makeSUT()
        let exp = expectation(description: "show filter chip")
        exp.assertForOverFulfill = false
        var receivedValue = true
        let cancellable = sut.$shouldShowFilterChip
            .dropFirst()
            .sink { shouldShowFilterChip in
                receivedValue = shouldShowFilterChip
                exp.fulfill()
            }
        
        syncModel.editMode = .inactive
        await fulfillment(of: [exp], timeout: 0.5)
        
        XCTAssertTrue(receivedValue)
        cancellable.cancel()
    }
    
    @MainActor
    func testInit_whenIsEditing_shouldNotShowFilterChip() async {
        let (sut, _, _, syncModel) = makeSUT()
        let exp = expectation(description: "should not show filter chip")
        exp.assertForOverFulfill = false
        var receivedValue = true
        let cancellable = sut.$shouldShowFilterChip
            .dropFirst()
            .sink { shouldShowFilterChip in
                receivedValue = shouldShowFilterChip
                exp.fulfill()
            }
        
        syncModel.editMode = .active
        await Task.yield()
        await Task.yield()
        await Task.yield()
        await fulfillment(of: [exp], timeout: 1)
        
        XCTAssertFalse(receivedValue)
        cancellable.cancel()
    }
    
    // MARK: - onViewAppear
    
    @MainActor
    func testOnViewAppear_whenCalled_executeSearchUseCase() async {
        let (sut, _, photoLibraryUseCase, _) = makeSUT()
        var subscriptions = Set<AnyCancellable>()
        var receivedMessages: [MockPhotoLibraryUseCase.Message] = []
        let messagesExp = expectation(description: "spy expectation")
        await photoLibraryUseCase.$messages
            .receive(on: DispatchQueue.main)
            .filter { !$0.isEmpty }
            .sink { messages in
                receivedMessages = messages
                messagesExp.fulfill()
            }
            .store(in: &subscriptions)
        
        trackTaskCancellation { await sut.onViewAppear() }
        
        await fulfillment(of: [messagesExp], timeout: 1)

        XCTAssertTrue(receivedMessages.contains(.media), "Expect to search")
    }

    @MainActor
    func testOnViewAppear_whenError_showsErrorView() async {
        let (sut, _, _, _) = makeSUT(photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: [], succesfullyLoadMedia: false))
        
        let messagesExp = expectation(description: "spy expectation")
        let cancellation = sut.$viewState
            .filter { $0 == .error }
            .sink { viewState in
                XCTAssertEqual(viewState, .error)
                messagesExp.fulfill()
            }

        weak var _sut = sut
        trackTaskCancellation { @MainActor in
            await _sut?.onViewAppear()
        }
        
        await fulfillment(of: [messagesExp], timeout: 1)
        cancellation.cancel()
    }
    
    @MainActor
    func testOnViewAppear_whenNoErrors_showsEmptyItemView() async {
        let (sut, _, _, _) = makeSUT(photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: []))
        
        let messagesExp = expectation(description: "spy expectation")
        let cancellation = sut.$viewState
            .filter { $0 == .empty }
            .sink { viewState in
                XCTAssertEqual(viewState, .empty)
                messagesExp.fulfill()
            }

        trackTaskCancellation { await sut.onViewAppear() }
        
        await fulfillment(of: [messagesExp], timeout: 1)
        cancellation.cancel()
        
        XCTAssertEqual(sut.videos.isEmpty, true)
    }
    
    @MainActor
    func testOnViewAppear_whenNoErrors_showsVideoItems() async {
        let foundVideos = [ anyNode(id: 1, mediaType: .video), anyNode(id: 2, mediaType: .video) ]
        let (sut, _, _, _) = makeSUT(photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: foundVideos))
        
        let messagesExp = expectation(description: "spy expectation")
        let cancellation = sut.$viewState
            .filter { $0 == .loaded }
            .sink { viewState in
                XCTAssertEqual(viewState, .loaded)
                messagesExp.fulfill()
            }

        trackTaskCancellation { await sut.onViewAppear() }
        
        await fulfillment(of: [messagesExp], timeout: 1)
        cancellation.cancel()
        
        XCTAssertEqual(sut.videos, foundVideos)
    }
    
    @MainActor
    func testOnViewAppear_whenLoadVideosSuccessfully_showsCorrectViewState() async {
        let (sut, _, _, _) = makeSUT(photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: [], succesfullyLoadMedia: true))
        var viewStates: [VideoListViewModel.ViewState] = []
        let exp = expectation(description: "view state subscription")
        exp.expectedFulfillmentCount = 3
        let cancellable = sut.$viewState
            .sink { viewState in
                viewStates.append(viewState)
                exp.fulfill()
            }
        
        trackTaskCancellation { await sut.onViewAppear() }

        await fulfillment(of: [exp], timeout: 0.5)

        XCTAssertEqual(viewStates, [ .partial, .loading, .empty ])
        
        cancellable.cancel()
    }
    
    @MainActor
    func testOnViewAppear_whenLoadVideosFailed_showsCorrectLoadingState() async {
        let (sut, _, _, _) = makeSUT(photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: [], succesfullyLoadMedia: false))
        var viewStates: [VideoListViewModel.ViewState] = []
        let exp = expectation(description: "view state subscription")
        exp.expectedFulfillmentCount = 3
        let cancellable = sut.$viewState
            .sink { viewState in
                viewStates.append(viewState)
                exp.fulfill()
            }
        
        trackTaskCancellation { await sut.onViewAppear() }
        
        await fulfillment(of: [exp], timeout: 0.5)
        XCTAssertEqual(viewStates, [ .partial, .loading, .error ])
        cancellable.cancel()
    }
    
    // MARK: - listenNodesUpdate
    
    @MainActor
    func testOnNodesUpdate_whenHasNodeUpdatesOnNonVideoNodes_doesNotUpdateUI() async throws {
        let videoNodes = [
            anyNode(id: 1, mediaType: .video),
            anyNode(id: 2, mediaType: .video)
        ]
        let nonVideosUpdateNodes = [
            anyNode(id: 1, mediaType: .image),
            anyNode(id: 2, mediaType: .image)
        ]
        let (stream, continuation) = AsyncStream<[NodeEntity]>.makeStream()
        let (sut, _, _, _) = makeSUT(
            fileSearchUseCase: MockFilesSearchUseCase(
                nodeUpdates: stream.eraseToAnyAsyncSequence()
            ),
            photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: videoNodes)
        )
        
        let exp = expectation(description: "wait for subscription")
        let cancellable = sut.$videos
            .filter(\.isNotEmpty)
            .sink { videos in
                XCTAssertEqual(videos, videoNodes)
                exp.fulfill()
            }
        
        trackTaskCancellation { await sut.onViewAppear() }
        
        continuation.yield(nonVideosUpdateNodes)
        continuation.finish()
        
        await fulfillment(of: [exp], timeout: 1)
        cancellable.cancel()
    }
        
    // MARK: - listenSearchTextChange
    
    @MainActor
    func testListenSearchTextChange_whenEmitsNewValue_performSearch() async {
        let photoLibraryUseCase = MockPhotoLibraryUseCase(allVideos: [])
        let syncModel = VideoRevampSyncModel()
         let sut = VideoListViewModel(
            syncModel: syncModel,
            contentProvider: VideoListViewModelContentProvider(photoLibraryUseCase: photoLibraryUseCase),
            selection: VideoSelection(),
            fileSearchUseCase: MockFilesSearchUseCase(),
            thumbnailLoader: MockThumbnailLoader(),
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(),
            nodeUseCase: MockNodeUseCase(),
            featureFlagProvider: MockFeatureFlagProvider(list: [:])
        )
        
        trackTaskCancellation { await sut.onViewAppear() }
        
        let exp = expectation(description: "search message found")
        let cancellation = await photoLibraryUseCase.$messages
            .receive(on: DispatchQueue.main)
            .first { $0 == [ .media ] }
            .sink { messages in
                XCTAssertEqual(messages, [ .media ])
                exp.fulfill()
            }

        syncModel.searchText = "any search text"

        await fulfillment(of: [exp], timeout: 1.0)
        cancellation.cancel()
    }
    
    @MainActor
    func testListenSearchTextChange_whenEmitsNewValueOnSuccess_showsVideos() async {
        // Arrange
        let videoNodes = [
            anyNode(id: 1, mediaType: .video),
            anyNode(id: 2, mediaType: .video)
        ]
        let syncModel = VideoRevampSyncModel()
        let photoLibraryUseCase = MockPhotoLibraryUseCase(allVideos: videoNodes)
        let sut = VideoListViewModel(
            syncModel: syncModel,
            contentProvider: VideoListViewModelContentProvider(photoLibraryUseCase: photoLibraryUseCase),
            selection: VideoSelection(),
            fileSearchUseCase: MockFilesSearchUseCase(),
            thumbnailLoader: MockThumbnailLoader(),
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(),
            nodeUseCase: MockNodeUseCase(),
            featureFlagProvider: MockFeatureFlagProvider(list: [:])
        )
        trackTaskCancellation { await sut.onViewAppear() }
        
        // Act
        syncModel.searchText = "any search text"
        
        var receivedViewState: [VideoListViewModel.ViewState] = []
        let viewStateExp = expectation(description: "ViewState expectation")
        viewStateExp.expectedFulfillmentCount = 3
        let viewStateCancellable = sut.$viewState
            .sink { viewState in
                receivedViewState.append(viewState)
                viewStateExp.fulfill()
            }
        await fulfillment(of: [viewStateExp], timeout: 1.0)
        viewStateCancellable.cancel()
        
        let exp = expectation(description: "search message found")
        let cancellation = await photoLibraryUseCase.$messages
            .first { $0 == [ .media ] }
            .sink { _ in exp.fulfill() }
        await fulfillment(of: [exp], timeout: 1.0)
        cancellation.cancel()
        
        let videosExp = expectation(description: "wait for videos")
        var cancellables = Set<AnyCancellable>()
        var capturedValues = [NodeEntity]()
        sut.$videos
            .sink {
                capturedValues = $0
                videosExp.fulfill()
            }
            .store(in: &cancellables)
        await fulfillment(of: [videosExp], timeout: 1.0)
        
        // Assert
        XCTAssertEqual(receivedViewState, [ .partial, .loading, .loaded ], "Should not show error when success search")
        XCTAssertTrue(capturedValues.isNotEmpty)
        cancellables = []
    }
    
    // MARK: - Cell Selection
    
    @MainActor
    func testToggleSelectAllVideos_onCalledAgain_shouldToggleBetweenSelectAllAndUnselectAll() async {
        let videoNodes = [
            anyNode(id: 1, mediaType: .video),
            anyNode(id: 2, mediaType: .video)
        ]
        let (sut, _, _, _) = makeSUT(
            photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: videoNodes)
        )
        let videosExp = expectation(description: "wait for videos")
        let cancellable = sut.$videos
            .filter(\.isNotEmpty)
            .sink { videos in
                XCTAssertEqual(Set(videos), Set(videoNodes))
                videosExp.fulfill()
            }
        
        trackTaskCancellation { await sut.onViewAppear() }
        
        await fulfillment(of: [videosExp], timeout: 1.0)

        sut.toggleSelectAllVideos()
        
        XCTAssertTrue(sut.selection.allSelected)
        
        sut.toggleSelectAllVideos()
        
        XCTAssertFalse(sut.selection.allSelected)
        XCTAssertTrue(sut.selection.videos.isEmpty)
        XCTAssertTrue(sut.videos.isNotEmpty)
        cancellable.cancel()
    }
    
    // MARK: - didFinishSelectFilterOption
    
    @MainActor
    func testDidFinishSelectFilterOption_whenSelectOptionOfLocationChip_toggleLocationChip() async throws {
        // Arrange
        let selectedFilterOptionType: LocationChipFilterOptionType = locationFilterOptionOnlyThatMakesActivateChipVisually()
        let (sut, _, _, _) = makeSUT(
            photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: [])
        )
        let selectedChip = try XCTUnwrap(
            sut.chips.first(where: { $0.type == .location }),
            "Expect to have Location chip"
        )
        sut.selectedLocationFilterOption = selectedFilterOptionType.stringValue
        
        let exp = expectation(description: "selected location filter option triggered")
        let cancellation = sut.$selectedLocationFilterOption
            .receive(on: DispatchQueue.main)
            .sink { selectedLocationFilterOption in
                XCTAssertEqual(selectedLocationFilterOption, selectedFilterOptionType.stringValue)
                XCTAssertFalse(sut.isSheetPresented)
                exp.fulfill()
            }
        await fulfillment(of: [exp], timeout: 0.5)
        
        // Act
        sut.didFinishSelectFilterOption(selectedChip)
        
        // Assert
        let locationChip = try XCTUnwrap(sut.chips.first(where: { $0.type == .location }), "Expect to have Location chip")
        let durationChip = try XCTUnwrap(sut.chips.first(where: { $0.type == .duration }), "Expect to have Duration chip")
        XCTAssertTrue(locationChip.isActive)
        XCTAssertFalse(durationChip.isActive)
        cancellation.cancel()
        
        try await Task.sleep(nanoseconds: 1_000_000)
    }
    
    @MainActor
    func testDidFinishSelectFilterOption_whenSelectOptionOfDurationChip_toggleDurationChip() async throws {
        // Arrange
        let selectedFilterOptionType: DurationChipFilterOptionType = durationFilterOptionOnlyThatMakesActivateChipVisually()
        let (sut, _, _, _) = makeSUT(
            photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: [])
        )
        let selectedChip = try XCTUnwrap(
            sut.chips.first(where: { $0.type == .duration }),
            "Expect to have Duration chip"
        )
        sut.selectedDurationFilterOption = selectedFilterOptionType.stringValue
        
        let exp = expectation(description: "selected location filter option triggered")
        let cancellation = sut.$selectedDurationFilterOption
            .receive(on: DispatchQueue.main)
            .sink { selectedDurationFilterOption in
                XCTAssertEqual(selectedDurationFilterOption, selectedFilterOptionType.stringValue)
                XCTAssertFalse(sut.isSheetPresented)
                exp.fulfill()
            }
        await fulfillment(of: [exp], timeout: 0.5)
        
        // Act
        sut.didFinishSelectFilterOption(selectedChip)
        
        // Assert
        let locationChip = try XCTUnwrap(sut.chips.first(where: { $0.type == .location }), "Expect to have Location chip")
        let durationChip = try XCTUnwrap(sut.chips.first(where: { $0.type == .duration }), "Expect to have Duration chip")
        XCTAssertFalse(locationChip.isActive)
        XCTAssertTrue(durationChip.isActive)
        cancellation.cancel()
        
        try await Task.sleep(nanoseconds: 1_000_000)
    }
    
    @MainActor
    func testDidFinishSelectFilterOption_whenSelectDefaultOptionOfLocationChip_toggleLocationChipToInactive() async throws {
        // Arrange 1 - previously select cloud drive
        let previousFilterOptionType: LocationChipFilterOptionType = .cloudDrive
        let (sut, _, _, _) = makeSUT(
            photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: [])
        )
        let selectedChip1 = try XCTUnwrap(
            sut.chips.first(where: { $0.type == .location }),
            "Expect to have Location chip"
        )
        sut.selectedLocationFilterOption = previousFilterOptionType.stringValue
        
        let exp1 = expectation(description: "selected location filter option triggered")
        let cancellation1 = sut.$selectedLocationFilterOption
            .receive(on: DispatchQueue.main)
            .sink { selectedLocationFilterOption in
                XCTAssertEqual(selectedLocationFilterOption, previousFilterOptionType.stringValue)
                XCTAssertFalse(sut.isSheetPresented)
                exp1.fulfill()
            }
        await fulfillment(of: [exp1], timeout: 0.5)
        
        // Act 1
        sut.didFinishSelectFilterOption(selectedChip1)
        
        // Assert 1
        let locationChip = try XCTUnwrap(sut.chips.first(where: { $0.type == .location }), "Expect to have Location chip")
        let durationChip = try XCTUnwrap(sut.chips.first(where: { $0.type == .duration }), "Expect to have Duration chip")
        XCTAssertTrue(locationChip.isActive)
        XCTAssertFalse(durationChip.isActive)
        cancellation1.cancel()
        
        // Arrange 2 - select default option
        let selectedFilterOptionType: LocationChipFilterOptionType = .allLocation
        sut.selectedLocationFilterOption = selectedFilterOptionType.stringValue
        
        let exp2 = expectation(description: "selected location filter option triggered")
        let cancellation2 = sut.$selectedLocationFilterOption
            .receive(on: DispatchQueue.main)
            .sink { selectedLocationFilterOption in
                XCTAssertEqual(selectedLocationFilterOption, selectedFilterOptionType.stringValue)
                XCTAssertFalse(sut.isSheetPresented)
                exp2.fulfill()
            }
        await fulfillment(of: [exp2], timeout: 0.5)
        
        // Act 2
        let selectedChip2 = try XCTUnwrap(
            sut.chips.first(where: { $0.type == .location }),
            "Expect to have Location chip"
        )
        sut.didFinishSelectFilterOption(selectedChip2)
        
        // Assert 2
        let latestLocationChip = try XCTUnwrap(sut.chips.first(where: { $0.type == .location }), "Expect to have Location chip")
        let latestDurationChip = try XCTUnwrap(sut.chips.first(where: { $0.type == .duration }), "Expect to have Duration chip")
        XCTAssertFalse(latestLocationChip.isActive)
        XCTAssertFalse(latestDurationChip.isActive)
        cancellation2.cancel()
        
        try await Task.sleep(nanoseconds: 1_000_000)
    }
    
    @MainActor
    func testDidFinishSelectFilterOption_whenSelectDefaultOptionOfDurationChip_toggleDurationChipToInactive() async throws {
        // Arrange 1 - previously select cloud drive
        let previousFilterOptionType: DurationChipFilterOptionType = .between10And60Seconds
        let (sut, _, _, _) = makeSUT(
            photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: [])
        )
        let selectedChip1 = try XCTUnwrap(
            sut.chips.first(where: { $0.type == .duration }),
            "Expect to have Location chip"
        )
        sut.selectedDurationFilterOption = previousFilterOptionType.stringValue
        
        let exp1 = expectation(description: "selected duration filter option triggered")
        let cancellation1 = sut.$selectedDurationFilterOption
            .receive(on: DispatchQueue.main)
            .sink { selectedDurationFilterOption in
                XCTAssertEqual(selectedDurationFilterOption, previousFilterOptionType.stringValue)
                XCTAssertFalse(sut.isSheetPresented)
                exp1.fulfill()
            }
        await fulfillment(of: [exp1], timeout: 0.5)
        
        // Act 1
        sut.didFinishSelectFilterOption(selectedChip1)
        
        // Assert 1
        let locationChip = try XCTUnwrap(sut.chips.first(where: { $0.type == .location }), "Expect to have Location chip")
        let durationChip = try XCTUnwrap(sut.chips.first(where: { $0.type == .duration }), "Expect to have Duration chip")
        XCTAssertFalse(locationChip.isActive)
        XCTAssertTrue(durationChip.isActive)
        cancellation1.cancel()
        
        // Arrange 2 - select default option
        let selectedFilterOptionType: DurationChipFilterOptionType = .allDurations
        sut.selectedDurationFilterOption = selectedFilterOptionType.stringValue
        
        let exp2 = expectation(description: "selected location filter option triggered")
        let cancellation2 = sut.$selectedDurationFilterOption
            .receive(on: DispatchQueue.main)
            .sink { selectedDurationFilterOption in
                XCTAssertEqual(selectedDurationFilterOption, selectedFilterOptionType.stringValue)
                XCTAssertFalse(sut.isSheetPresented)
                exp2.fulfill()
            }
        await fulfillment(of: [exp2], timeout: 0.5)
        
        // Act 2
        let selectedChip2 = try XCTUnwrap(
            sut.chips.first(where: { $0.type == .duration }),
            "Expect to have Location chip"
        )
        sut.didFinishSelectFilterOption(selectedChip2)
        
        // Assert 2
        let latestLocationChip = try XCTUnwrap(sut.chips.first(where: { $0.type == .location }), "Expect to have Location chip")
        let latestDurationChip = try XCTUnwrap(sut.chips.first(where: { $0.type == .duration }), "Expect to have Duration chip")
        XCTAssertFalse(latestLocationChip.isActive)
        XCTAssertFalse(latestDurationChip.isActive)
        cancellation2.cancel()
        
        try await Task.sleep(nanoseconds: 1_000_000)
    }
    
    // MARK: - filterOptions
    @MainActor
    func testFilterOptions_whenNotSelectAnyChips_doNotRenderOptionsForBottomSheetFilter() async {
        let (sut, _, _, _) = makeSUT(
            photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: [])
        )
        
        XCTAssertTrue(sut.filterOptions.isEmpty)
    }
    
    @MainActor
    func testFilterOptions_whenSelectLocationFilterChips_rendersCorrectOptionsForBottomSheetFilter() throws {
        let (sut, _, _, _) = makeSUT(
            photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: [])
        )
        
        let locationChip = try XCTUnwrap(
            sut.chips.first(where: { $0.type == .location }),
            "Expect to have Location chip"
        )
        sut.newlySelectedChip = locationChip
        
        XCTAssertEqual(sut.filterOptions, LocationChipFilterOptionType.allCases.map(\.stringValue))
    }
    
    @MainActor
    func testFilterOptions_whenSelectDurationFilterChips_rendersCorrectOptionsForBottomSheetFilter() throws {
        let (sut, _, _, _) = makeSUT(
            photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: [])
        )
        
        let durationChip = try XCTUnwrap(
            sut.chips.first(where: { $0.type == .duration }),
            "Expect to have Duration chip"
        )
        sut.newlySelectedChip = durationChip
        
        XCTAssertEqual(sut.filterOptions, DurationChipFilterOptionType.allCases.map(\.stringValue))
    }
    
    @MainActor
    func testFilter_whenFilterByDuration_allDurations_shouldFilterVideosByDuration() async throws {
        let videoNodes = [
            anyNode(id: 1, mediaType: .video, duration: 241), // between4And20Minutes
            anyNode(id: 2, mediaType: .video, duration: 1200) // moreThan20Minutes
        ]
        let (sut, _, _, _) = makeSUT(
            photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: videoNodes)
        )
        sut.selectedDurationFilterOption = DurationChipFilterOptionType.allDurations.stringValue
        trackTaskCancellation { await sut.onViewAppear() }
        
        let videosExp = expectation(description: "wait for videos")
        let cancellable = sut.$videos
            .filter(\.isNotEmpty)
            .receive(on: DispatchQueue.main)
            .sink { videos in
                XCTAssertEqual(Set(videos), Set(videoNodes))
                videosExp.fulfill()
            }
        
        await fulfillment(of: [videosExp], timeout: 1.0)
        cancellable.cancel()
    }
    
    @MainActor
    func testFilter_whenFilterByDuration_lessThan10Seconds_shouldFilterVideosByDuration() async throws {
        let videoNodes = [
            anyNode(id: 1, mediaType: .video, duration: 2), // lessThan10Seconds
            anyNode(id: 2, mediaType: .video, duration: 1200) // moreThan20Minutes
        ]
        let (sut, _, photoLibraryUseCase, _) = makeSUT(
            photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: videoNodes)
        )
        
        let expectedVideos = { (expectedVideos: [NodeEntity]) in
            let videosExp = self.expectation(description: "wait for videos")
            let cancellable = sut.$videos
                .first(where: { Set($0) == Set(expectedVideos) })
                .sink { _ in videosExp.fulfill() }
            await self.fulfillment(of: [videosExp], timeout: 1.0)
            cancellable.cancel()
        }
                
        trackTaskCancellation { await sut.onViewAppear() }
        
        await expectedVideos(videoNodes)
        
        let messages = await photoLibraryUseCase.messages
        XCTAssertEqual(messages, [ .media ])
        
        sut.selectedDurationFilterOption = DurationChipFilterOptionType.lessThan10Seconds.stringValue
        
        await expectedVideos(videoNodes.filter { $0.duration < 10 })

        let messages2 = await photoLibraryUseCase.messages
        XCTAssertEqual(messages2, [ .media, .media ]) // load media again after the filter
    }
    
    @MainActor
    func testFilter_whenFilterByDuration_between10And60Seconds_shouldFilterVideosByDuration() async throws {
        
        let videoNodes = [
            anyNode(id: 1, mediaType: .video, duration: 11), // between10And60Seconds
            anyNode(id: 2, mediaType: .video, duration: 1200) // moreThan20Minutes
        ]
        
        let (sut, _, photoLibraryUseCase, _) = makeSUT(
            photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: videoNodes)
        )
        
        let expectedVideos = { (expectedVideos: [NodeEntity]) in
            let videosExp = self.expectation(description: "wait for videos")
            let cancellable = sut.$videos
                .first(where: { Set($0) == Set(expectedVideos) })
                .sink { _ in videosExp.fulfill() }
            await self.fulfillment(of: [videosExp], timeout: 1.0)
            cancellable.cancel()
        }
        
        trackTaskCancellation { await sut.onViewAppear() }
        
        await expectedVideos(videoNodes)
        let messages = await photoLibraryUseCase.messages
        XCTAssertEqual(messages, [ .media ])
        
        sut.selectedDurationFilterOption = DurationChipFilterOptionType.between10And60Seconds.stringValue
        
        await expectedVideos(videoNodes.filter { $0.duration >= 10 && $0.duration < 60 })
        let messages2 = await photoLibraryUseCase.messages
        XCTAssertEqual(messages2, [ .media, .media ]) // load media again after the filter
    }
    
    @MainActor
    func testFilter_whenFilterByDuration_between1And4Minutes_shouldFilterVideosByDuration() async throws {
        let videoNodes = [
            anyNode(id: 1, mediaType: .video, duration: 61), // between1And4Minutes
            anyNode(id: 2, mediaType: .video, duration: 1200) // moreThan20Minutes
        ]
        let (sut, _, photoLibraryUseCase, _) = makeSUT(
            photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: videoNodes)
        )
        
        let expectedVideos = { (expectedVideos: [NodeEntity]) in
            let videosExp = self.expectation(description: "wait for videos")
            let cancellable = sut.$videos
                .first(where: { Set($0) == Set(expectedVideos) })
                .sink { _ in videosExp.fulfill() }
            await self.fulfillment(of: [videosExp], timeout: 1.0)
            cancellable.cancel()
        }
        
        trackTaskCancellation { await sut.onViewAppear() }
        
        await expectedVideos(videoNodes)
        let messages = await photoLibraryUseCase.messages
        XCTAssertEqual(messages, [ .media ])
        
        sut.selectedDurationFilterOption = DurationChipFilterOptionType.between1And4Minutes.stringValue

        await expectedVideos(videoNodes.filter { $0.duration >= 60 && $0.duration < 240 })
        let messages2 = await photoLibraryUseCase.messages
        XCTAssertEqual(messages2, [ .media, .media ]) // load media again after the filter
    }
    
    @MainActor
    func testFilter_whenFilterByDuration_between4And20Minutes_shouldFilterVideosByDuration() async throws {
        let videoNodes = [
            anyNode(id: 1, mediaType: .video, duration: 241), // between1And4Minutes
            anyNode(id: 2, mediaType: .video, duration: 1200) // moreThan20Minutes
        ]
        let (sut, _, photoLibraryUseCase, _) = makeSUT(
            photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: videoNodes)
        )
        
        let expectedVideos = { (expectedVideos: [NodeEntity]) in
            let videosExp = self.expectation(description: "wait for videos")
            let cancellable = sut.$videos
                .first(where: { Set($0) == Set(expectedVideos) })
                .sink { _ in videosExp.fulfill() }
            await self.fulfillment(of: [videosExp], timeout: 1.0)
            cancellable.cancel()
        }
        
        trackTaskCancellation { await sut.onViewAppear() }
        
        await expectedVideos(videoNodes)
        let messages = await photoLibraryUseCase.messages
        XCTAssertEqual(messages, [ .media ])
        
        sut.selectedDurationFilterOption = DurationChipFilterOptionType.between4And20Minutes.stringValue
        await expectedVideos(videoNodes.filter { $0.duration >= 240 && $0.duration < 1200 })

        let messages2 = await photoLibraryUseCase.messages
        XCTAssertEqual(messages2, [ .media, .media ]) // load media again after the filter
    }
    
    @MainActor
    func testFilter_whenFilterByDuration_moreThan20Minutes_shouldFilterVideosByDuration() async throws {
        let videoNodes = [
            anyNode(id: 1, mediaType: .video, duration: 241), // between4And20Minutes
            anyNode(id: 2, mediaType: .video, duration: 1200) // moreThan20Minutes
        ]
        let (sut, _, photoLibraryUseCase, _) = makeSUT(
            photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: videoNodes)
        )
        
        let expectedVideos = { (expectedVideos: [NodeEntity]) in
            let videosExp = self.expectation(description: "wait for videos")
            let cancellable = sut.$videos
                .first(where: { Set($0) == Set(expectedVideos) })
                .sink { _ in videosExp.fulfill() }
            await self.fulfillment(of: [videosExp], timeout: 1.0)
            cancellable.cancel()
        }
        
        trackTaskCancellation { await sut.onViewAppear() }
        
        await expectedVideos(videoNodes)
        let messages = await photoLibraryUseCase.messages
        
        XCTAssertEqual(messages, [ .media ])
        XCTAssertEqual(sut.videos, videoNodes)
        
        sut.selectedDurationFilterOption = DurationChipFilterOptionType.moreThan20Minutes.stringValue
        
        await expectedVideos(videoNodes.filter { $0.duration >= 1200 })
        let messages2 = await photoLibraryUseCase.messages
        XCTAssertEqual(messages2, [ .media, .media ]) // load media again after the filter
    }
    
    @MainActor
    func testFilter_whenFilterByLocation_shouldFilterVideosByLocation() async throws {
        let videoNodes = [
            anyNode(id: 1, mediaType: .video),
            anyNode(id: 2, mediaType: .video)
        ]
        let cloudDriveNodes = [
            anyNode(id: 1, mediaType: .video)
        ]
        let (sut, _, photoLibraryUseCase, _) = makeSUT(
            photoLibraryUseCase: MockPhotoLibraryUseCase(
                allPhotosFromCloudDriveOnly: cloudDriveNodes, 
                allVideos: videoNodes
            )
        )
        
        let expectedVideos = { (expectedVideos: [NodeEntity]) in
            let videosExp = self.expectation(description: "wait for videos")
            let cancellable = sut.$videos
                .first(where: { Set($0) == Set(expectedVideos) })
                .sink { _ in videosExp.fulfill() }
            await self.fulfillment(of: [videosExp], timeout: 1.0)
            cancellable.cancel()
        }
        
        trackTaskCancellation { await sut.onViewAppear() }
        await expectedVideos(videoNodes)
        let messages = await photoLibraryUseCase.messages
        XCTAssertEqual(messages, [ .media ])
        
        sut.selectedLocationFilterOption = LocationChipFilterOptionType.cloudDrive.stringValue
        await expectedVideos(cloudDriveNodes)
        let messages2 = await photoLibraryUseCase.messages
        XCTAssertEqual(messages2, [ .media, .media ]) // load media again after the filter
    }
    
    @MainActor
    func testFilter_whenFilterByLocationOnlySharedItems_shouldFilterVideosByLocation() async throws {
        let videoNodes = [
            anyNode(id: 1, mediaType: .video, isExported: false),
            anyNode(id: 2, mediaType: .video, isExported: false)
        ]
        let (sut, _, photoLibraryUseCase, _) = makeSUT(
            photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: videoNodes)
        )
        
        let expectedVideos = { (expectedVideos: [NodeEntity]) in
            let videosExp = self.expectation(description: "wait for videos")
            let cancellable = sut.$videos
                .first(where: { Set($0) == Set(expectedVideos) })
                .sink { _ in videosExp.fulfill() }
            await self.fulfillment(of: [videosExp], timeout: 1.0)
            cancellable.cancel()
        }
        
        trackTaskCancellation { await sut.onViewAppear() }
        
        await expectedVideos(videoNodes)
        let messages = await photoLibraryUseCase.messages
        XCTAssertEqual(messages, [ .media ])
        
        sut.selectedLocationFilterOption = LocationChipFilterOptionType.sharedItems.stringValue
        
        await expectedVideos([])
        let messages2 = await photoLibraryUseCase.messages
        XCTAssertEqual(messages2, [ .media, .media ]) // load media again after the filter
    }
    
    // MARK: - actionSheetTitle
    @MainActor
    func testActionSheetTitle_whenNotSelectAnyChips_doNotRenderActionSheetTitle() {
        let (sut, _, _, _) = makeSUT(
            photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: [])
        )
        
        XCTAssertTrue(sut.actionSheetTitle.isEmpty)
    }
    
    @MainActor
    func testActionSheetTitle_whenSelectAnyChips_renderCorrectActionSheetTitle() {
        let (sut, _, _, _) = makeSUT(
            photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: [])
        )
        
        for (index, chip) in sut.chips.enumerated() {
            sut.newlySelectedChip = chip
            
            XCTAssertEqual(sut.actionSheetTitle, chip.title, "Expect to render correct title, but failed at index: \(index)")
        }
    }
    
    // MARK: - Helpers
    @MainActor
    private func makeSUT(
        fileSearchUseCase: some MockFilesSearchUseCase = MockFilesSearchUseCase(
            searchResult: .failure(.generic),
            onNodesUpdateResult: nil
        ),
        photoLibraryUseCase: some MockPhotoLibraryUseCase = MockPhotoLibraryUseCase(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: VideoListViewModel,
        fileSearchUseCase: MockFilesSearchUseCase,
        photoLibraryUseCase: MockPhotoLibraryUseCase,
        syncModel: VideoRevampSyncModel
    ) {
        let syncModel = VideoRevampSyncModel()
        let sut = VideoListViewModel(
            syncModel: syncModel,
            contentProvider: VideoListViewModelContentProvider(photoLibraryUseCase: photoLibraryUseCase),
            selection: VideoSelection(),
            fileSearchUseCase: fileSearchUseCase,
            thumbnailLoader: MockThumbnailLoader(),
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(),
            nodeUseCase: MockNodeUseCase(),
            featureFlagProvider: MockFeatureFlagProvider(list: [:])
        )
        trackForMemoryLeaks(on: sut, timeoutNanoseconds: 1_000_000_000, file: file, line: line)
        return (sut, fileSearchUseCase, photoLibraryUseCase, syncModel)
    }
    
    private func anyNode(id: HandleEntity, mediaType: MediaTypeEntity, name: String = "any", changeTypes: ChangeTypeEntity = .fileAttributes, duration: Int = 2, isExported: Bool = false) -> NodeEntity {
        NodeEntity(
            changeTypes: changeTypes,
            nodeType: .file,
            name: "\(name)-\(id).\(mediaType == .video ? "mov" : "png")",
            handle: id,
            isFile: true,
            hasThumbnail: true,
            hasPreview: true,
            isExported: isExported,
            label: .unknown,
            publicHandle: id,
            size: 2,
            duration: duration,
            mediaType: mediaType
        )
    }
    
    private func locationFilterOptionOnlyThatMakesActivateChipVisually() -> LocationChipFilterOptionType {
        LocationChipFilterOptionType.allCases
            .filter { $0 != .allLocation }
            .randomElement() ?? .cloudDrive
    }
    
    private func durationFilterOptionOnlyThatMakesActivateChipVisually() -> DurationChipFilterOptionType {
        DurationChipFilterOptionType.allCases
            .filter { $0 != .allDurations }
            .randomElement() ?? .between10And60Seconds
    }
}
