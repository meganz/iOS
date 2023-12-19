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
    }
    
    // MARK: - Dispatch.navigationBarAction.didSelectSortMenuAction
    
    func testDispatch_navigationBarActionDidSelectSortMenuAction_saveSortOrderPreference() {
        let selectedSortType = anySortOrderType()
        let (sut, sortOrderPreferenceUseCase) = makeSUT()
        
        sut.dispatch(.navigationBarAction(.didSelectSortMenuAction(sortType: selectedSortType)))
        
        XCTAssertEqual(sortOrderPreferenceUseCase.saveSortOrderCallCount, 1)
    }
    
    func testDispatch_navigationBarActionDidSelectSortMenuAction_updatesSortOrderTypeToUI() {
        let selectedSortType = anySortOrderType()
        let (sut, _) = makeSUT()
        
        var receivedCommands = [VideoRevampTabContainerViewModel.Command]()
        sut.invokeCommand = { command in
            receivedCommands.append(command)
        }
        
        sut.dispatch(.navigationBarAction(.didSelectSortMenuAction(sortType: selectedSortType)))
        
        XCTAssertEqual(sut.videoRevampSortOrderType, selectedSortType)
        XCTAssertEqual(receivedCommands, [ .navigationBarCommand(.refreshContextMenu) ])
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
        XCTAssertEqual(sut.isEditing, true)
    }
    
    func testDispatch_navigationBarActionDidReceivedDisplayMenuActionSort_setsVideoRevampSortOrderType() {
        let (sut, sortOrderPreferenceUseCase) = makeSUT()
        
        sut.dispatch(.navigationBarAction(.didReceivedDisplayMenuAction(action: .sort)))
        
        XCTAssertEqual(sortOrderPreferenceUseCase.getSortOrderCallCount, 1)
    }
    
    // MARK: - Dispatch.navigationBarAction.didTapCancel
    
    func testDispatch_navigationBarActionDidTapCancel_setsIsEditing() {
        let (sut, _) = makeSUT()
        
        sut.dispatch(.navigationBarAction(.didTapCancel))
        
        XCTAssertEqual(sut.isEditing, false)
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
