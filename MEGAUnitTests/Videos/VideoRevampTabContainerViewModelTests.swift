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
        
        XCTAssertEqual(sortOrderPreferenceUseCase.getSortOrderCallCount, 0)
    }
    
    // MARK: - Dispatch.onViewDidLoad
    
    func testDispatch_onViewDidLoad_executeUseCases() {
        let (sut, sortOrderPreferenceUseCase, _) = makeSUT()
        
        sut.dispatch(.onViewDidLoad)
        
        XCTAssertEqual(sortOrderPreferenceUseCase.getSortOrderCallCount, 1)
        XCTAssertEqual(sortOrderPreferenceUseCase.monitorSortOrderCallCount, 1)
    }
    
    // MARK: - Dispatch.navigationBarAction.didSelectSortMenuAction
    
    func testDispatch_navigationBarActionDidSelectSortMenuAction_saveSortOrderPreference() {
        let selectedSortType = anySortOrderType()
        let (sut, sortOrderPreferenceUseCase, _) = makeSUT()
        
        sut.dispatch(.navigationBarAction(.didSelectSortMenuAction(sortType: selectedSortType)))
        
        XCTAssertEqual(sortOrderPreferenceUseCase.saveSortOrderCallCount, 1)
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
    
    // MARK: - Dispatch.navigationBarAction.didTapCancel
    
    func testDispatch_navigationBarActionDidTapCancel_setsIsEditing() {
        let (sut, _, _) = makeSUT()
        
        sut.dispatch(.navigationBarAction(.didTapCancel))
        
        XCTAssertEqual(sut.syncModel.editMode, .inactive)
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
    
    // MARK: - renderNavigationTitle
    
    func testDispatch_onViewDidLoad_navigationTitleBeDefault() {
        let (sut, _, _) = makeSUT()
        var receivedCommands = [VideoRevampTabContainerViewModel.Command]()
        sut.invokeCommand = { command in
            receivedCommands.append(command)
        }
        
        sut.dispatch(.onViewDidLoad)
        
        XCTAssertEqual(receivedCommands, [ .navigationBarCommand(.renderNavigationTitle(.videos)) ])
    }
    
    @MainActor
    func testInit_whenIsNotInEditingMode_renderDefaultVideosTitle() {
        let (sut, _, videoSelection) = makeSUT()
        let exp = expectation(description: "Wait for invokeCommand")
        var receivedCommands = [VideoRevampTabContainerViewModel.Command]()
        sut.invokeCommand = { command in
            if command == .navigationBarCommand(.renderNavigationTitle(.videos)) {
                receivedCommands.append(command)
                exp.fulfill()
            }
        }
        
        videoSelection.editMode = .inactive
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertTrue(receivedCommands.contains(.navigationBarCommand(.renderNavigationTitle(.videos))))
    }
    
    @MainActor
    func testInit_whenIsInEditingMode_renderSelectItemsTitle() {
        let (sut, _, videoSelection) = makeSUT()
        let exp = expectation(description: "Wait for invokeCommand")
        var receivedCommands = [VideoRevampTabContainerViewModel.Command]()
        sut.invokeCommand = { command in
            if command == .navigationBarCommand(.renderNavigationTitle(.selectItems)) {
                receivedCommands.append(command)
                exp.fulfill()
            }
        }
        
        videoSelection.editMode = .active
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertTrue(receivedCommands.contains(.navigationBarCommand(.renderNavigationTitle(.selectItems))))
    }
    
    @MainActor
    func testInit_whenIsInEditingModeAndSelectingAVideo_renderSelectItemsWithCountTitle() {
        let (sut, _, videoSelection) = makeSUT()
        let exp = expectation(description: "Wait for invokeCommand")
        var receivedCommands = [VideoRevampTabContainerViewModel.Command]()
        sut.invokeCommand = { command in
            if command != .navigationBarCommand(.renderNavigationTitle(.selectItems))
                && command != .navigationBarCommand(.renderNavigationTitle(.videos)) {
                receivedCommands.append(command)
                exp.fulfill()
            }
        }
        
        videoSelection.editMode = .active
        videoSelection.videos = [1: anyNode(id: 1, mediaType: .video)]
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertTrue(receivedCommands.contains(.navigationBarCommand(.renderNavigationTitle(.selectItemsWithCount(1)))))
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
            videoSelection: videoSelection
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
