@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGATest
import Video
import XCTest

final class VideoRevampTabContainerViewModelTests: XCTestCase {
    
    // MARK: - Init
    
    func testInit_whenCalled_doesNotExecuteUseCases() {
        let (_, sortOrderPreferenceUseCase, _) = makeSUT()
        
        XCTAssertTrue(sortOrderPreferenceUseCase.messages.isEmpty)
    }
    
    // MARK: - Dispatch.onViewDidLoad
    
    func testDispatch_onViewDidLoad_executeUseCases() {
        let (sut, sortOrderPreferenceUseCase, _) = makeSUT()
        
        sut.dispatch(.onViewDidLoad)
        
        let availablePreferenceKeys: [SortOrderPreferenceKeyEntity] = [ .homeVideos, .homeVideoPlaylists ]
        availablePreferenceKeys.enumerated().forEach { (index, key) in
            XCTAssertTrue(sortOrderPreferenceUseCase.messages.contains(.sortOrder(key: key)), "Fail at index: \(index) with key: \(key)")
            XCTAssertTrue(sortOrderPreferenceUseCase.messages.contains(.monitorSortOrder(key: key)), "Fail at index: \(index) with key: \(key)")
        }
    }
    
    // MARK: - Dispatch.navigationBarAction.didSelectSortMenuAction
    
    func testDispatch_navigationBarActionDidSelectSortMenuAction_saveSortOrderPreferenceForVideos() {
        let selectedSortType = anySortOrderType()
        let (sut, sortOrderPreferenceUseCase, _) = makeSUT()
        sut.syncModel.currentTab = .all
        
        sut.dispatch(.navigationBarAction(.didSelectSortMenuAction(sortType: selectedSortType)))
        
        XCTAssertEqual(sortOrderPreferenceUseCase.messages, [ .save(sortOrder: selectedSortType.toSortOrderEntity(), for: .homeVideos) ])
    }
    
    func testDispatch_navigationBarActionDidSelectSortMenuAction_saveSortOrderPreferenceForVideoPlaylists() {
        let selectedSortType: SortOrderType = .newest
        let (sut, sortOrderPreferenceUseCase, _) = makeSUT()
        sut.syncModel.currentTab = .playlist
        
        sut.dispatch(.navigationBarAction(.didSelectSortMenuAction(sortType: selectedSortType)))
        
        XCTAssertEqual(sortOrderPreferenceUseCase.messages, [ .save(sortOrder: selectedSortType.toVideoPlaylistSortOrderEntity(), for: .homeVideoPlaylists) ])
    }
    
    // MARK: - Dispatch.navigationBarAction.didReceivedDisplayMenuAction
    
    func testDispatch_navigationBarActionDidReceivedDisplayMenuActionSelect_toggleEditing() {
        let (sut, _, _) = makeSUT()
        
        var receivedCommands = [VideoRevampTabContainerViewModel.Command]()
        sut.invokeCommand = { command in
            receivedCommands.append(command)
        }
        
        sut.dispatch(.navigationBarAction(.didReceivedDisplayMenuAction(action: .select)))
        
        XCTAssertTrue(receivedCommands.contains(.navigationBarCommand(.toggleEditing)))
        XCTAssertEqual(sut.syncModel.editMode, .active)
    }
    
    func testDispatch_navigationBarActionDidReceivedDisplayMenuActionNewPlaylist_showsShowNewPlaylistAlert() {
        let (sut, _, _) = makeSUT()
        
        sut.dispatch(.navigationBarAction(.didReceivedDisplayMenuAction(action: .newPlaylist)))
        
        XCTAssertTrue(sut.syncModel.shouldShowAddNewPlaylistAlert)
    }
    
    // MARK: - Dispatch.navigationBarAction.didTapCancel
    
    func testDispatch_navigationBarActionDidTapCancel_setsIsEditing() {
        let (sut, _, _) = makeSUT()
        
        sut.dispatch(.navigationBarAction(.didTapCancel))
        
        XCTAssertEqual(sut.syncModel.editMode, .inactive)
    }
    
    func testDispatch_navigationBarActionDidTapCancel_searchShouldNotActive() {
        let (sut, _, _) = makeSUT()
        
        sut.dispatch(.navigationBarAction(.didTapCancel))
        
        XCTAssertFalse(sut.syncModel.isSearchActive)
        XCTAssertTrue(sut.syncModel.showsTabView)
    }
    
    // MARK: - Dispatch.navigationBarAction.didTapSelectAll
    
    func testDispatch_navigationBarActionDidTapSelectAll_initialStateShouldFalse() {
        let (sut, _, _) = makeSUT()
        
        XCTAssertFalse(sut.syncModel.isAllSelected)
    }
    
    func testDispatch_navigationBarActionDidTapSelectAll_selectAllAndUnselectAll() {
        let (sut, _, _) = makeSUT()
        
        sut.dispatch(.navigationBarAction(.didTapSelectAll))
        
        XCTAssertTrue(sut.syncModel.isAllSelected)
        
        sut.dispatch(.navigationBarAction(.didTapSelectAll))
        
        XCTAssertFalse(sut.syncModel.isAllSelected)
    }
    
    // MARK: - Dispatch.searchBarAction.updateSearchResults
    
    func testDispatch_searchBarActionUpdateSearchResultsWithText_sendsSearchTextToSyncModel() {
        let searchText = "any-search-keyword"
        let (sut, _, _) = makeSUT()
        
        sut.dispatch(.searchBarAction(.updateSearchResults(searchText: searchText)))
        
        XCTAssertEqual(sut.syncModel.searchText, searchText)
    }
    
    func testDispatch_searchBarActionUpdateSearchResultsWithEmpty_sendsSearchTextToSyncModel() {
        let searchText = ""
        let (sut, _, _) = makeSUT()
        
        sut.dispatch(.searchBarAction(.updateSearchResults(searchText: searchText)))
        
        XCTAssertEqual(sut.syncModel.searchText, searchText)
    }
    
    // MARK: - Dispatch.searchBarAction.cancel
    
    func testDispatch_searchBarActionCancel_sendsSearchTextToSyncModel() {
        let (sut, _, _) = makeSUT()
        
        sut.dispatch(.searchBarAction(.cancel))
        
        XCTAssertEqual(sut.syncModel.searchText, "")
    }
    
    func testDispatch_searchBarActionCancel_searchShouldBecomeInactive() {
        let (sut, _, _) = makeSUT()
        
        sut.dispatch(.searchBarAction(.cancel))
        
        XCTAssertFalse(sut.syncModel.isSearchActive)
    }
    
    // MARK: - Dispatch.searchBarAction.becomeActive
    
    func testDispatch_searchBarActionBecomeActive_searchShouldActivate() {
        let (sut, _, _) = makeSUT()
        
        sut.dispatch(.searchBarAction(.becomeActive))
        
        XCTAssertTrue(sut.syncModel.isSearchActive)
        XCTAssertFalse(sut.syncModel.showsTabView)
    }
    
    // MARK: - renderNavigationTitle
    
    func testDispatch_onViewDidLoad_navigationTitleBeDefault() {
        let (sut, _, _) = makeSUT()
        var receivedCommands = [VideoRevampTabContainerViewModel.Command]()
        sut.invokeCommand = { command in
            switch command {
            case .navigationBarCommand(.renderNavigationTitle):
                receivedCommands.append(command)
            default:
                break
            }
        }
        
        sut.dispatch(.onViewDidLoad)
        
        XCTAssertTrue(receivedCommands.contains(.navigationBarCommand(.renderNavigationTitle("Videos"))))
    }
    
    @MainActor
    func testInit_whenIsNotInEditingMode_renderDefaultVideosTitle() {
        let (sut, _, videoSelection) = makeSUT()
        let exp = expectation(description: "Wait for invokeCommand")
        var receivedCommands = [VideoRevampTabContainerViewModel.Command]()
        sut.invokeCommand = { command in
            switch command {
            case .navigationBarCommand(.renderNavigationTitle):
                receivedCommands.append(command)
                exp.fulfill()
            default:
                break
            }
        }
        
        videoSelection.editMode = .inactive
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertTrue(receivedCommands.contains(.navigationBarCommand(.renderNavigationTitle("Videos"))))
    }
    
    @MainActor
    func testInit_whenIsInEditingMode_renderSelectItemsTitle() {
        let (sut, _, videoSelection) = makeSUT()
        let exp = expectation(description: "Wait for invokeCommand")
        exp.expectedFulfillmentCount = 2
        var receivedCommands = [VideoRevampTabContainerViewModel.Command]()
        sut.invokeCommand = { command in
            switch command {
            case .navigationBarCommand(.renderNavigationTitle):
                receivedCommands.append(command)
                exp.fulfill()
            default:
                break
            }
        }
        
        videoSelection.editMode = .active
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertTrue(receivedCommands.contains(.navigationBarCommand(.renderNavigationTitle("Select items"))))
    }
    
    @MainActor
    func testInit_whenIsInEditingModeAndSelectingAVideo_renderSelectItemsWithCountTitle() {
        let (sut, _, videoSelection) = makeSUT()
        let exp = expectation(description: "Wait for invokeCommand")
        exp.expectedFulfillmentCount = 3
        var receivedCommands = [VideoRevampTabContainerViewModel.Command]()
        sut.invokeCommand = { command in
            switch command {
            case .navigationBarCommand(.renderNavigationTitle):
                receivedCommands.append(command)
                exp.fulfill()
            default:
                break
            }
        }
        
        videoSelection.editMode = .active
        videoSelection.videos = [1: anyNode(id: 1, mediaType: .video)]
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertTrue(receivedCommands.contains(.navigationBarCommand(.renderNavigationTitle("1 item selected"))))
    }
    
    // MARK: - Searching state behavior
    
    func testDispatch_navigationBarActionSelect_hidesSearchBar() {
        let (sut, _, _) = makeSUT()
        let exp = expectation(description: "Wait for invokeCommand")
        var receivedCommands = [VideoRevampTabContainerViewModel.Command]()
        sut.invokeCommand = { command in
            if command == .searchBarCommand(.hideSearchBar) {
                receivedCommands.append(command)
                exp.fulfill()
            }
        }
        
        sut.dispatch(.navigationBarAction(.didReceivedDisplayMenuAction(action: .select)))
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertTrue(receivedCommands.contains(.searchBarCommand(.hideSearchBar)))
    }
    
    func testDispatch_navigationBarActionSelect_resetsSearchState() {
        let (sut, _, _) = makeSUT()
        let exp = expectation(description: "Wait for invokeCommand")
        var receivedCommands = [VideoRevampTabContainerViewModel.Command]()
        sut.invokeCommand = { command in
            if command == .searchBarCommand(.hideSearchBar) {
                receivedCommands.append(command)
                exp.fulfill()
            }
        }
        
        sut.syncModel.searchText = "searching something"
        sut.dispatch(.navigationBarAction(.didReceivedDisplayMenuAction(action: .select)))
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.syncModel.searchText, "")
    }
    
    @MainActor
    func testDispatch_navigationBarActionSelect_hidesTabView() {
        let (sut, _, _) = makeSUT()
        let exp = expectation(description: "Wait for invokeCommand")
        var receivedCommands = [VideoRevampTabContainerViewModel.Command]()
        sut.invokeCommand = { command in
            if command == .searchBarCommand(.hideSearchBar) {
                receivedCommands.append(command)
                exp.fulfill()
            }
        }
        
        sut.dispatch(.navigationBarAction(.didReceivedDisplayMenuAction(action: .select)))
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertFalse(sut.syncModel.showsTabView)
    }
    
    func testDispatch_navigationBarActionDidTapCancel_reshowSearchBar() {
        let (sut, _, _) = makeSUT()
        let exp = expectation(description: "Wait for invokeCommand")
        var receivedCommands = [VideoRevampTabContainerViewModel.Command]()
        sut.invokeCommand = { command in
            if command == .searchBarCommand(.reshowSearchBar) {
                receivedCommands.append(command)
                exp.fulfill()
            }
        }
        
        sut.dispatch(.navigationBarAction(.didTapCancel))
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertTrue(receivedCommands.contains(.searchBarCommand(.reshowSearchBar)))
    }
    
    func testDispatch_navigationBarActionDidTapCancel_resetsSearchState() {
        let (sut, _, _) = makeSUT()
        sut.syncModel.searchText = "searching something"
        let exp = expectation(description: "Wait for invokeCommand")
        var receivedCommands = [VideoRevampTabContainerViewModel.Command]()
        sut.invokeCommand = { command in
            if command == .searchBarCommand(.reshowSearchBar) {
                receivedCommands.append(command)
                exp.fulfill()
            }
        }
        
        sut.dispatch(.navigationBarAction(.didTapCancel))
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.syncModel.searchText, "")
    }
    
    @MainActor
    func testDispatch_navigationBarActionDidTapCancel_showsTabView() {
        let (sut, _, _) = makeSUT()
        let exp = expectation(description: "Wait for invokeCommand")
        var receivedCommands = [VideoRevampTabContainerViewModel.Command]()
        sut.invokeCommand = { command in
            if command == .searchBarCommand(.reshowSearchBar) {
                receivedCommands.append(command)
                exp.fulfill()
            }
        }
        
        sut.dispatch(.navigationBarAction(.didTapCancel))
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertTrue(sut.syncModel.showsTabView)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: VideoRevampTabContainerViewModel,
        sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase,
        videoSelection: VideoSelection
    ) {
        let videoSelection = VideoSelection()
        let sortOrderPreferenceUseCase = MockSortOrderPreferenceUseCase(sortOrderEntity: .creationAsc)
        let sut = VideoRevampTabContainerViewModel(
            sortOrderPreferenceUseCase: sortOrderPreferenceUseCase,
            videoSelection: videoSelection,
            syncModel: VideoRevampSyncModel()
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return (sut, sortOrderPreferenceUseCase, videoSelection)
    }
    
    private func anySortOrderType() -> SortOrderType {
        .favourite
    }
    
    private func anyNode(id: HandleEntity, mediaType: MediaTypeEntity, name: String = "any", changeTypes: ChangeTypeEntity = .fileAttributes) -> NodeEntity {
        NodeEntity(
            changeTypes: changeTypes,
            nodeType: .file,
            name: name,
            handle: id,
            isFile: true,
            hasThumbnail: true,
            hasPreview: true,
            label: .unknown,
            publicHandle: id,
            size: 2,
            duration: 2,
            mediaType: mediaType
        )
    }
}
