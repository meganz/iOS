@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGATest
import Video
import XCTest

final class VideoPlaylistContentContainerViewModelTests: XCTestCase {
    
    // MARK: - Init
    
    @MainActor
    func testInit_whenCalled_LoadsSortOrder() {
        let (sut, sortOrderPreferenceUseCase) = makeSUT(sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase(sortOrderEntity: .defaultAsc))
        
        XCTAssertEqual(sortOrderPreferenceUseCase.monitorSortOrderCallCount, 1)
        cancelTask(on: sut)
    }
    
    @MainActor
    func testInit_whenCalled_loadValidSortOrder() {
        let validSortOrders = PlaylistContentSupportedSortOrderPolicy.supportedSortOrders
        let validSortOrder = validSortOrders.randomElement() ?? validSortOrders[0]
        let (sut, _) = makeSUT(sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase(sortOrderEntity: validSortOrder))
        
        var receivedSortOrder: SortOrderEntity?
        let exp = expectation(description: "sort order completion")
        let cancellable = sut.$sortOrder
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { sortOrder in
                receivedSortOrder = sortOrder
                exp.fulfill()
            }
        wait(for: [exp], timeout: 0.1)
        
        XCTAssertEqual(receivedSortOrder, validSortOrder)
        
        cancellable.cancel()
    }
    
    @MainActor
    func testInit_invalidSortOrder_useDefaultFallbackSortOrder() {
        let invalidSortOrder = invalidSortOrders().randomElement() ?? invalidSortOrders()[0]
        let (sut, _) = makeSUT(sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase(sortOrderEntity: invalidSortOrder))
        
        var receivedSortOrder: SortOrderEntity?
        let exp = expectation(description: "sort order completion")
        let cancellable = sut.$sortOrder
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { sortOrder in
                receivedSortOrder = sortOrder
                exp.fulfill()
            }
        wait(for: [exp], timeout: 0.1)
        
        XCTAssertEqual(receivedSortOrder, .modificationAsc)
        
        cancellable.cancel()
    }
    
    // MARK: - sortMenu
    
    @MainActor
    func testSortMenu_whenHasInValidSortOrderType_doesNotSaveSortOrder() {        
        invalidSortOrders().enumerated().forEach { (index, invalidSortOrder) in
            let (sut, sortOrderPreferenceUseCase) = makeSUT()
            
            sut.didSelectSortMenu(sortOrder: invalidSortOrder)
            
            XCTAssertTrue(
                sortOrderPreferenceUseCase.messages.notContains(.save(
                    sortOrder: invalidSortOrder,
                    for: .videoPlaylistContent
                )),
                "fail at index: \(index), with value: \(invalidSortOrder)"
            )
            cancelTask(on: sut)
        }
    }
    
    @MainActor
    func testSortMenu_whenHasValidSortOrderType_saveSortOrder() {
        let validSortOrders = PlaylistContentSupportedSortOrderPolicy.supportedSortOrders
        
        validSortOrders.enumerated().forEach { (index, validSortOrder) in
            let (sut, sortOrderPreferenceUseCase) = makeSUT()
            
            sut.didSelectSortMenu(sortOrder: validSortOrder)
            
            XCTAssertTrue(
                sortOrderPreferenceUseCase.messages.contains(.save(
                    sortOrder: validSortOrder,
                    for: .videoPlaylistContent
                )),
                "fail at index: \(index), with value: \(validSortOrder)"
            )
            cancelTask(on: sut)
        }
    }
    
    // MARK: - Helpers
    
    @MainActor
    private func makeSUT(
        sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase = MockSortOrderPreferenceUseCase(sortOrderEntity: .defaultAsc),
        file: StaticString = #file,
        line: UInt = #line
    ) -> (
        sut: VideoPlaylistContentContainerViewModel,
        sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase
    ) {
        let sut = VideoPlaylistContentContainerViewModel(
            sortOrderPreferenceUseCase: sortOrderPreferenceUseCase
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return (sut, sortOrderPreferenceUseCase)
    }
    
    @MainActor
    private func cancelTask(on sut: VideoPlaylistContentContainerViewModel) {
        sut.cancellables.forEach { $0.cancel() }
    }
    
    private func invalidSortOrders() -> [SortOrderEntity] {
        SortOrderEntity.allCases
            .filter { !PlaylistContentSupportedSortOrderPolicy.supportedSortOrders.contains($0) }
    }
}
