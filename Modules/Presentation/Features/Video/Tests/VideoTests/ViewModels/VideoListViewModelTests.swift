@preconcurrency import Combine
import MEGADomain
import MEGADomainMock
import MEGAPresentationMock
import MEGATest
@testable import Video
import XCTest

final class VideoListViewModelTests: XCTestCase {
    
    private var cancellables = Set<AnyCancellable>()
    
    func testInit_whenInit_doesNotExecuteSearchOnUseCase() async {
        let (_, _, photoLibraryUseCase, _) = makeSUT()
        
        let messages = await photoLibraryUseCase.messages
        XCTAssertTrue(messages.isEmpty, "Expect to not search on creation")
    }
    
    func testInit_whenInit_doNotListenToNodesUpdate() {
        let (_, fileSearchUseCase, _, _) = makeSUT()
        
        XCTAssertTrue(fileSearchUseCase.messages.isEmpty, "Expect to not listen nodes update")
    }
    
    // MARK: - init.monitorSortOrderChanged
    
    @MainActor
    func testMonitorSortOrderChanged_whenHasNoSortOrderChanged_doesNotReloadVideos() async {
        // Arrange
        let (sut, _, photoLibraryUseCase, syncModel) = makeSUT()
        
        let sortOrderExp = expectation(description: "sort order changed")
        sortOrderExp.isInverted = true
        let cancellable = syncModel.$videoRevampSortOrderType
            .dropFirst()
            .sink { _ in
                sortOrderExp.fulfill()
            }
        
        let messagesExp = expectation(description: "spy expectation")
        var receivedMessages: [MockPhotoLibraryUseCase.Message]?
        messagesExp.assertForOverFulfill = false
        let cancellable2 = await photoLibraryUseCase.$messages
            .sink { messages in
                receivedMessages = messages
                messagesExp.fulfill()
            }
        
        // Act
        await sut.reloadVideosOnSortOrderChangedTask?.value
        await fulfillment(of: [sortOrderExp, messagesExp], timeout: 0.5)
        
        // Assert
        XCTAssertTrue(receivedMessages?.notContains(.media) == true)
        
        cancellable.cancel()
        cancellable2.cancel()
    }
    
    @MainActor
    func testMonitorSortOrderChanged_whenHasSortOrderChanged_reloadVideos() async throws {
        // Arrange
        let (sut, _, photoLibraryUseCase, syncModel) = makeSUT(photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: [], succesfullyLoadMedia: true))
        syncModel.videoRevampSortOrderType = .favouriteAsc
        
        let sortOrderExp = expectation(description: "sort order changed")
        sortOrderExp.assertForOverFulfill = false
        let cancellable = syncModel.$videoRevampSortOrderType
            .dropFirst()
            .sink { _ in
                sortOrderExp.fulfill()
            }
        
        let messagesExp = expectation(description: "spy expectation")
        var receivedMessages: [MockPhotoLibraryUseCase.Message]?
        messagesExp.assertForOverFulfill = false
        let cancellable2 = await photoLibraryUseCase.$messages
            .dropFirst()
            .sink { messages in
                receivedMessages = messages
                messagesExp.fulfill()
            }
        
        // Act
        syncModel.videoRevampSortOrderType = .labelDesc
        await sut.reloadVideosOnSortOrderChangedTask?.value
        
        // Assert
        XCTAssertTrue(receivedMessages?.contains(.media) == true)
        
        cancellable.cancel()
        cancellable2.cancel()
        sut.reloadVideosOnSortOrderChangedTask?.cancel()
        await fulfillment(of: [sortOrderExp, messagesExp], timeout: 0.5)
    }
    
    // MARK: - init.subscribeToEditingMode
    
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
        await fulfillment(of: [exp], timeout: 0.5)
        
        XCTAssertFalse(receivedValue)
        cancellable.cancel()
    }
    
    // MARK: - onViewAppear
    
    @MainActor
    func testOnViewAppear_whenCalled_executeSearchUseCase() async {
        let (sut, _, photoLibraryUseCase, _) = makeSUT()
        
        await sut.onViewAppear()
        
        let messages = await photoLibraryUseCase.messages
        XCTAssertTrue(messages.contains(.media), "Expect to search")
    }
    
    @MainActor
    func testOnViewAppear_whenCalledOnFailedLoadVideos_executesSearchUseCaseInOrder() async {
        let (sut, _, photoLibraryUseCase, _) = makeSUT()
        
        await sut.onViewAppear()
        
        let messages = await photoLibraryUseCase.messages
        XCTAssertEqual(messages, [ .media ])
    }
    
    @MainActor
    func testOnViewAppear_whenCalledOnSuccessfullyLoadVideos_executesSearchUseCaseInOrder() async {
        let (sut, _, photoLibraryUseCase, _) = makeSUT(fileSearchUseCase: MockFilesSearchUseCase(searchResult: .success(nil)))
        
        await sut.onViewAppear()
        
        let messages = await photoLibraryUseCase.messages
        XCTAssertEqual(messages, [ .media ])
    }
    
    @MainActor
    func testOnViewAppear_whenError_showsErrorView() async {
        let (sut, _, _, _) = makeSUT(photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: [], succesfullyLoadMedia: false))
        
        await sut.onViewAppear()
        
        XCTAssertEqual(sut.shouldShowError, true)
    }
    
    @MainActor
    func testOnViewAppear_whenNoErrors_showsEmptyItemView() async {
        let (sut, _, _, _) = makeSUT(photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: []))
        
        await sut.onViewAppear()
        
        XCTAssertEqual(sut.videos.isEmpty, true)
    }
    
    @MainActor
    func testOnViewAppear_whenNoErrors_showsVideoItems() async {
        let foundVideos = [ anyNode(id: 1, mediaType: .video), anyNode(id: 2, mediaType: .video) ]
        let (sut, _, _, _) = makeSUT(photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: foundVideos))
        
        await sut.onViewAppear()
        
        XCTAssertEqual(sut.videos, foundVideos)
    }
    
    @MainActor
    func testOnViewAppear_whenLoadVideosSuccessfully_showsCorrectLoadingState() async {
        let (sut, _, _, _) = makeSUT(photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: [], succesfullyLoadMedia: true))
        var loadingStates: [Bool] = []
        let exp = expectation(description: "loading state subscription")
        exp.assertForOverFulfill = false
        let cancellable = sut.$shouldShowPlaceHolderView
            .sink { isLoading in
                loadingStates.append(isLoading)
                exp.fulfill()
            }
        
        await sut.onViewAppear()
        
        XCTAssertEqual(loadingStates, [ false, true, false ])
        
        cancellable.cancel()
        await fulfillment(of: [exp], timeout: 0.5)
    }
    
    @MainActor
    func testOnViewAppear_whenLoadVideosFailed_showsCorrectLoadingState() async {
        let (sut, _, _, _) = makeSUT(photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: [], succesfullyLoadMedia: false))
        var loadingStates: [Bool] = []
        let exp = expectation(description: "loading state subscription")
        exp.assertForOverFulfill = false
        let cancellable = sut.$shouldShowPlaceHolderView
            .sink { isLoading in
                loadingStates.append(isLoading)
                exp.fulfill()
            }
        
        await sut.onViewAppear()
        
        XCTAssertEqual(loadingStates, [ false, true, false ])
        
        cancellable.cancel()
        await fulfillment(of: [exp], timeout: 0.5)
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
        let (sut, _, _, _) = makeSUT(
            fileSearchUseCase: MockFilesSearchUseCase(
                nodeUpdates: [nonVideosUpdateNodes].async.eraseToAnyAsyncSequence()
            ),
            photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: videoNodes)
        )
        await sut.onViewAppear()
        
        var receivedVideos: [NodeEntity] = []
        let exp = expectation(description: "wait for subscription")
        let cancellable = sut.$videos
            .sink { videos in
                receivedVideos = videos
                exp.fulfill()
            }
        
        trackTaskCancellation { await sut.listenNodesUpdate() }

        await fulfillment(of: [exp], timeout: 0.5)
        
        XCTAssertEqual(receivedVideos, videoNodes)
        cancellable.cancel()
    }
    
    @MainActor
    func testOnNodesUpdate_whenHasNodeUpdatesOnVideoNodes_updatesUI() async throws {
        let attributesRelatedChangeTypes: ChangeTypeEntity = [ .attributes, .fileAttributes, .favourite, .publicLink ]
        let initialVideoNodes = [
            anyNode(id: 1, mediaType: .video, name: "old video name"),
            anyNode(id: 2, mediaType: .image, name: "old image name")
        ]
        let updatedVideoNodes = [
            anyNode(id: 1, mediaType: .video, name: "new video name", changeTypes: attributesRelatedChangeTypes)
        ]
        let (sut, _, _, _) = makeSUT(
            fileSearchUseCase: MockFilesSearchUseCase(
                nodeUpdates: [updatedVideoNodes].async.eraseToAnyAsyncSequence()
            ),
            photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: initialVideoNodes)
        )
        await sut.onViewAppear()
        
        var receivedVideos: [NodeEntity] = []
        let exp = expectation(description: "wait for subscription")
        exp.assertForOverFulfill = false
        let cancellable = sut.$videos
            .sink { videos in
                receivedVideos = videos
                exp.fulfill()
            }
        
        trackTaskCancellation { await sut.listenNodesUpdate() }

        await sut.reloadVideosTask?.value
        await fulfillment(of: [exp], timeout: 0.5)
        
        XCTAssertEqual(receivedVideos.count, 2)
        XCTAssertEqual(receivedVideos.first, updatedVideoNodes.first)
        XCTAssertEqual(receivedVideos.last, initialVideoNodes.last)
        cancellable.cancel()
    }
    
    @MainActor
    func testOnNodesUpdate_whenHasNodeUpdatesOnVideoNodesButNonValidChangeTypes_doesNotUpdateUI() async throws {
        let invalidChangeTypes: ChangeTypeEntity = [ .removed, .timestamp ]
        let initialVideoNodes = [
            anyNode(id: 1, mediaType: .video, name: "old video name"),
            anyNode(id: 2, mediaType: .image, name: "old image name")
        ]
        let updatedVideoNodes = [
            anyNode(id: 1, mediaType: .video, name: "new video name", changeTypes: invalidChangeTypes)
        ]
        let (sut, _, _, _) = makeSUT(
            fileSearchUseCase: MockFilesSearchUseCase(
                nodeUpdates: [updatedVideoNodes].async.eraseToAnyAsyncSequence()
            ),
            photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: initialVideoNodes)
        )
        await sut.onViewAppear()
        
        var receivedVideos: [NodeEntity] = []
        let exp = expectation(description: "wait for subscription")
        exp.assertForOverFulfill = false
        let cancellable = sut.$videos
            .sink { videos in
                receivedVideos = videos
                exp.fulfill()
            }
        
        trackTaskCancellation { await sut.listenNodesUpdate() }
        await sut.reloadVideosTask?.value
        await fulfillment(of: [exp], timeout: 0.5)
        
        XCTAssertEqual(receivedVideos.count, 2)
        XCTAssertEqual(receivedVideos, initialVideoNodes)
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
            sensitiveNodeUseCase: MockSensitiveNodeUseCase()
        )
        
        trackTaskCancellation { await sut.listenSearchTextChange() }
        
        syncModel.searchText = "any search text"
        
        let exp = expectation(description: "search message found")
        let cancellation = await photoLibraryUseCase.$messages
            .first { $0 == [ .media ] }
            .sink { messages in
                XCTAssertEqual(messages, [ .media ])
                exp.fulfill()
            }
        await fulfillment(of: [exp], timeout: 1.0)
        cancellation.cancel()
    }
    
    @MainActor
    func testListenSearchTextChange_whenEmitsNewValueOnSuccess_showsVideos() async {
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
            sensitiveNodeUseCase: MockSensitiveNodeUseCase()
        )
        
        let task = Task {
            await sut.listenSearchTextChange()
        }
        syncModel.searchText = "any search text"
        let exp = expectation(description: "search message found")
        let cancellation = await photoLibraryUseCase.$messages
            .first { $0 == [ .media ] }
            .sink { _ in exp.fulfill() }
        
        await fulfillment(of: [exp], timeout: 1.0)
        cancellation.cancel()
        task.cancel()
        
        let videosExp = expectation(description: "wait for videos")
        var capturedValues = [NodeEntity]()
        sut.$videos
            .sink {
                capturedValues = $0
                videosExp.fulfill()
            }
            .store(in: &cancellables)
        await fulfillment(of: [videosExp], timeout: 1.0)
        XCTAssertFalse(sut.shouldShowError, "Should not show error when success search")
        XCTAssertTrue(capturedValues.isNotEmpty)
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
        await sut.onViewAppear()
        
        sut.toggleSelectAllVideos()
        
        XCTAssertTrue(sut.selection.allSelected)
        XCTAssertEqual(Set(sut.videos), Set(videoNodes))
        
        sut.toggleSelectAllVideos()
        
        XCTAssertFalse(sut.selection.allSelected)
        XCTAssertTrue(sut.selection.videos.isEmpty)
        XCTAssertTrue(sut.videos.isNotEmpty)
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
                XCTAssertEqual(sut.selectedLocationFilterOptionType, LocationChipFilterOptionType(rawValue: selectedFilterOptionType.stringValue))
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
                XCTAssertEqual(sut.selectedDurationFilterOptionType, DurationChipFilterOptionType(rawValue: selectedFilterOptionType.stringValue))
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
                XCTAssertEqual(sut.selectedLocationFilterOptionType, LocationChipFilterOptionType(rawValue: previousFilterOptionType.stringValue))
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
                XCTAssertEqual(sut.selectedLocationFilterOptionType, LocationChipFilterOptionType(rawValue: selectedFilterOptionType.stringValue))
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
                XCTAssertEqual(sut.selectedDurationFilterOptionType, DurationChipFilterOptionType(rawValue: previousFilterOptionType.stringValue))
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
                XCTAssertEqual(sut.selectedDurationFilterOptionType, DurationChipFilterOptionType(rawValue: selectedFilterOptionType.stringValue))
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
    
    func testFilterOptions_whenNotSelectAnyChips_doNotRenderOptionsForBottomSheetFilter() async {
        let (sut, _, _, _) = makeSUT(
            photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: [])
        )
        
        XCTAssertTrue(sut.filterOptions.isEmpty)
    }
    
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
        let (sut, _, photoLibraryUseCase, _) = makeSUT(
            photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: videoNodes)
        )
        await sut.onViewAppear()
        let messages = await photoLibraryUseCase.messages
        
        XCTAssertEqual(messages, [ .media ])
        XCTAssertEqual(sut.videos, videoNodes)
        
        sut.selectedDurationFilterOption = DurationChipFilterOptionType.allDurations.stringValue
        try await Task.sleep(nanoseconds: 1_000_000)
        
        let messages2 = await photoLibraryUseCase.messages
        XCTAssertEqual(messages2, [ .media, .media ]) // load media again after the filter
        XCTAssertEqual(sut.videos, videoNodes)
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
        await sut.onViewAppear()
        let messages = await photoLibraryUseCase.messages
        
        XCTAssertEqual(messages, [ .media ])
        XCTAssertEqual(sut.videos, videoNodes)
        
        sut.selectedDurationFilterOption = DurationChipFilterOptionType.lessThan10Seconds.stringValue
        try await Task.sleep(nanoseconds: 1_000_000)
        
        let messages2 = await photoLibraryUseCase.messages
        XCTAssertEqual(messages2, [ .media, .media ]) // load media again after the filter
        XCTAssertTrue(sut.videos.allSatisfy { $0.duration < 10 })
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
        await sut.onViewAppear()
        let messages = await photoLibraryUseCase.messages
        
        XCTAssertEqual(messages, [ .media ])
        XCTAssertEqual(sut.videos, videoNodes)
        
        sut.selectedDurationFilterOption = DurationChipFilterOptionType.between10And60Seconds.stringValue
        try await Task.sleep(nanoseconds: 1_000_000)
        
        let messages2 = await photoLibraryUseCase.messages
        XCTAssertEqual(messages2, [ .media, .media ]) // load media again after the filter
        XCTAssertTrue(sut.videos.allSatisfy { $0.duration >= 10 && $0.duration < 60 })
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
        await sut.onViewAppear()
        let messages = await photoLibraryUseCase.messages
        
        XCTAssertEqual(messages, [ .media ])
        XCTAssertEqual(sut.videos, videoNodes)
        
        sut.selectedDurationFilterOption = DurationChipFilterOptionType.between1And4Minutes.stringValue
        try await Task.sleep(nanoseconds: 1_000_000)
        
        let messages2 = await photoLibraryUseCase.messages
        XCTAssertEqual(messages2, [ .media, .media ]) // load media again after the filter
        XCTAssertTrue(sut.videos.allSatisfy { $0.duration >= 60 && $0.duration < 240 })
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
        await sut.onViewAppear()
        let messages = await photoLibraryUseCase.messages
        
        XCTAssertEqual(messages, [ .media ])
        XCTAssertEqual(sut.videos, videoNodes)
        
        sut.selectedDurationFilterOption = DurationChipFilterOptionType.between4And20Minutes.stringValue
        try await Task.sleep(nanoseconds: 1_000_000)
        
        let messages2 = await photoLibraryUseCase.messages
        XCTAssertEqual(messages2, [ .media, .media ]) // load media again after the filter
        XCTAssertTrue(sut.videos.allSatisfy { $0.duration >= 240 && $0.duration < 1200 })
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
        await sut.onViewAppear()
        let messages = await photoLibraryUseCase.messages
        
        XCTAssertEqual(messages, [ .media ])
        XCTAssertEqual(sut.videos, videoNodes)
        
        sut.selectedDurationFilterOption = DurationChipFilterOptionType.moreThan20Minutes.stringValue
        try await Task.sleep(nanoseconds: 1_000_000)
        
        let messages2 = await photoLibraryUseCase.messages
        XCTAssertEqual(messages2, [ .media, .media ]) // load media again after the filter
        XCTAssertTrue(sut.videos.allSatisfy { $0.duration >= 1200 })
    }
    
    @MainActor
    func testFilter_whenFilterByLocation_shouldFilterVideosByLocation() async throws {
        let videoNodes = [
            anyNode(id: 1, mediaType: .video),
            anyNode(id: 2, mediaType: .video)
        ]
        let (sut, _, photoLibraryUseCase, _) = makeSUT(
            photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: videoNodes)
        )
        await sut.onViewAppear()
        let messages = await photoLibraryUseCase.messages
        
        XCTAssertEqual(messages, [ .media ])
        XCTAssertEqual(sut.videos, videoNodes)
        
        sut.selectedLocationFilterOption = LocationChipFilterOptionType.cloudDrive.stringValue
        try await Task.sleep(nanoseconds: 1_000_000)
        
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
        await sut.onViewAppear()
        let messages = await photoLibraryUseCase.messages
        
        XCTAssertEqual(messages, [ .media ])
        XCTAssertEqual(sut.videos, videoNodes)
        
        sut.selectedLocationFilterOption = LocationChipFilterOptionType.sharedItems.stringValue
        try await Task.sleep(nanoseconds: 1_000_000)
        
        let messages2 = await photoLibraryUseCase.messages
        XCTAssertEqual(messages2, [ .media, .media ]) // load media again after the filter
        XCTAssertTrue(sut.videos.isEmpty)
    }
    
    // MARK: - actionSheetTitle
    
    func testActionSheetTitle_whenNotSelectAnyChips_doNotRenderActionSheetTitle() {
        let (sut, _, _, _) = makeSUT(
            photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: [])
        )
        
        XCTAssertTrue(sut.actionSheetTitle.isEmpty)
    }
    
    func testActionSheetTitle_whenSelectAnyChips_renderCorrectActionSheetTitle() {
        let (sut, _, _, _) = makeSUT(
            photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: [])
        )
        
        for (index, chip) in sut.chips.enumerated() {
            sut.newlySelectedChip = chip
            
            XCTAssertEqual(sut.actionSheetTitle, chip.title, "Expect to render correct title, but failed at index: \(index)")
        }
    }
    
    // MARK: - selectedLocationFilterOption
    
    func testSelectedLocationFilterOption_onValueChanged_reflectSelectedLocationFilterOptionType() async throws {
        let (sut, _, _, _) = makeSUT(
            photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: [])
        )
        
        sut.selectedLocationFilterOption = LocationChipFilterOptionType.allLocation.stringValue
        try await Task.sleep(nanoseconds: 1_000_000)
        
        XCTAssertEqual(sut.selectedLocationFilterOptionType, .allLocation)
    }
    
    func testSelectedLocationFilterOption_onValueChanged_reflectsSelectedLocationFilterOptionType() async throws {
        let (sut, _, _, _) = makeSUT(
            photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: [])
        )
        
        sut.selectedDurationFilterOption = DurationChipFilterOptionType.allDurations.stringValue
        try await Task.sleep(nanoseconds: 1_000_000)
        
        XCTAssertEqual(sut.selectedDurationFilterOptionType, .allDurations)
    }
    
    // MARK: - subscribeToItemsStateForEmptyState
    
    @MainActor
    func testSubscribeToItemsStateForEmptyState_whenConditionNotMet_shouldNotShowEmptyView() async {
        // Arrange
        let (sut, _, _, _) = makeSUT(photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: [], succesfullyLoadMedia: false))
        
        var receivedValue = false
        let exp = expectation(description: "should not show empty view")
        exp.isInverted = true
        let cancellable = sut.$shouldShowVideosEmptyView
            .dropFirst()
            .sink { shouldShow in
                receivedValue = shouldShow
                exp.fulfill()
            }
        
        await sut.onViewAppear()
        await fulfillment(of: [exp], timeout: 0.5)
        
        // Assert
        XCTAssertFalse(receivedValue)
        
        cancellable.cancel()
    }
    
    @MainActor
    func testSubscribeToItemsStateForEmptyState_whenConditionMet_shouldShowEmptyView() async {
        // Arrange
        let videoNodes = [
            anyNode(id: 1, mediaType: .video),
            anyNode(id: 2, mediaType: .video)
        ]
        let (sut, _, _, _) = makeSUT(photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: videoNodes, succesfullyLoadMedia: true))
        
        var receivedValue = false
        let exp = expectation(description: "should show empty view")
        exp.assertForOverFulfill = false
        let cancellable = sut.$shouldShowVideosEmptyView
            .dropFirst()
            .sink { shouldShow in
                receivedValue = shouldShow
                exp.fulfill()
            }
        
        await sut.onViewAppear()
        await fulfillment(of: [exp], timeout: 0.5)
        
        // Assert
        XCTAssertFalse(receivedValue)
        
        cancellable.cancel()
    }
    
    // MARK: - Helpers
    
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
            sensitiveNodeUseCase: MockSensitiveNodeUseCase()
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return (sut, fileSearchUseCase, photoLibraryUseCase, syncModel)
    }
    
    private func anyNode(id: HandleEntity, mediaType: MediaTypeEntity, name: String = "any", changeTypes: ChangeTypeEntity = .fileAttributes, duration: Int = 2, isExported: Bool = false) -> NodeEntity {
        NodeEntity(
            changeTypes: changeTypes,
            nodeType: .file,
            name: "\(name)-\(id).mov",
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
