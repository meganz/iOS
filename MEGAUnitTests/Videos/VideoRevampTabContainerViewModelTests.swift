@testable import MEGA
import MEGADomainMock
import MEGATest
import XCTest

final class VideoRevampTabContainerViewModelTests: XCTestCase {
    
    // MARK: - Init

    func testInit_whenCalled_doesNotExecuteUseCases() {
        let (_, sortOrderPreferenceUseCase) = makeSUT()
        
        XCTAssertEqual(sortOrderPreferenceUseCase.getSortOrderCallCount, 0)
    }
    
    // MARK: - Dispatch.onViewDidLoad
    
    func testDispatch_onViewDidLoad_executeUseCases() {
        let (sut, sortOrderPreferenceUseCase) = makeSUT()
        
        sut.dispatch(.onViewDidLoad)
        
        XCTAssertEqual(sortOrderPreferenceUseCase.getSortOrderCallCount, 1)
        XCTAssertEqual(sortOrderPreferenceUseCase.monitorSortOrderCallCount, 1)
    }
    
    // MARK: - Dispatch.navigationBarAction.didSelectSortMenuAction
    
    func testDispatch_navigationBarActionDidSelectSortMenuAction_saveSortOrderPreference() {
        let selectedSortType = anySortOrderType()
        let (sut, sortOrderPreferenceUseCase) = makeSUT()
        
        sut.dispatch(.navigationBarAction(.didSelectSortMenuAction(sortType: selectedSortType)))
        
        XCTAssertEqual(sortOrderPreferenceUseCase.saveSortOrderCallCount, 1)
    }
    
    // MARK: - Dispatch.navigationBarAction.didReceivedDisplayMenuAction
    
    func testDispatch_navigationBarActionDidReceivedDisplayMenuActionSelect_toggleEditing() {
        let (sut, _) = makeSUT()
        
        var receivedCommands = [VideoRevampTabContainerViewModel.Command]()
        sut.invokeCommand = { command in
            receivedCommands.append(command)
        }
        
        sut.dispatch(.navigationBarAction(.didReceivedDisplayMenuAction(action: .select)))
        
        XCTAssertEqual(receivedCommands, [ .navigationBarCommand(.toggleEditing) ])
        XCTAssertEqual(sut.syncModel.editMode, .active)
    }
    
    // MARK: - Dispatch.navigationBarAction.didTapCancel
    
    func testDispatch_navigationBarActionDidTapCancel_setsIsEditing() {
        let (sut, _) = makeSUT()
        
        sut.dispatch(.navigationBarAction(.didTapCancel))
        
        XCTAssertEqual(sut.syncModel.editMode, .inactive)
    }
    
    // MARK: - Dispatch.navigationBarAction.didTapSelectAll
    
    func testDispatch_navigationBarActionDidTapSelectAll_initialStateShouldFalse() {
        let (sut, _) = makeSUT()
        
        XCTAssertFalse(sut.syncModel.isAllSelected)
    }
    
    func testDispatch_navigationBarActionDidTapSelectAll_selectAllAndUnselectAll() {
        let (sut, _) = makeSUT()
        
        sut.dispatch(.navigationBarAction(.didTapSelectAll))
        
        XCTAssertTrue(sut.syncModel.isAllSelected)
        
        sut.dispatch(.navigationBarAction(.didTapSelectAll))
        
        XCTAssertFalse(sut.syncModel.isAllSelected)
    }
    
    // MARK: - Dispatch.searchBarAction.updateSearchResults
    
    func testDispatch_searchBarActionUpdateSearchResultsWithText_sendsSearchTextToSyncModel() {
        let searchText = "any-search-keyword"
        let (sut, _) = makeSUT()
        
        sut.dispatch(.searchBarAction(.updateSearchResults(searchText: searchText)))
        
        XCTAssertEqual(sut.syncModel.searchText, searchText)
    }
    
    func testDispatch_searchBarActionUpdateSearchResultsWithEmpty_sendsSearchTextToSyncModel() {
        let searchText = ""
        let (sut, _) = makeSUT()
        
        sut.dispatch(.searchBarAction(.updateSearchResults(searchText: searchText)))
        
        XCTAssertEqual(sut.syncModel.searchText, searchText)
    }
    
    // MARK: - Dispatch.searchBarAction.cancel
    
    func testDispatch_searchBarActionCancel_sendsSearchTextToSyncModel() {
        let (sut, _) = makeSUT()
        
        sut.dispatch(.searchBarAction(.cancel))
        
        XCTAssertEqual(sut.syncModel.searchText, "")
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: VideoRevampTabContainerViewModel,
        sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase
    ) {
        let sortOrderPreferenceUseCase = MockSortOrderPreferenceUseCase(sortOrderEntity: .creationAsc)
        let sut = VideoRevampTabContainerViewModel(
            sortOrderPreferenceUseCase: sortOrderPreferenceUseCase
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return (sut, sortOrderPreferenceUseCase)
    }
    
    private func anySortOrderType() -> SortOrderType {
        .favourite
    }
}
