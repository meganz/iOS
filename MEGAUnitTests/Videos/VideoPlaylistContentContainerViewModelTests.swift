@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGATest
import Testing
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
            sortOrderPreferenceUseCase: sortOrderPreferenceUseCase,
            overDiskQuotaChecker: MockOverDiskQuotaChecker()
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

@Suite("VideoPlaylistContentContainerViewModel Tests")
struct VideoPlaylistContentContainerViewModelTestSuite {
    @Suite("Selected action")
    struct Actions {
        @Suite("Menu Action")
        @MainActor
        struct MenuAction {
            @Test("when over disk quota reached for new playlist, should not set display action entity",
                  arguments: [
                    (true, DisplayActionEntity.newPlaylist, Optional<DisplayActionEntity>.none),
                    (false, .newPlaylist, .some(.newPlaylist)),
                    (true, .select, .some(.select))]
            )
            func overDiskQuota(
                isPaywalled: Bool,
                action: DisplayActionEntity,
                expectedAction: DisplayActionEntity?
            ) {
                let overDiskQuotaChecker = MockOverDiskQuotaChecker(isPaywalled: isPaywalled)
                let sut = makeSUT(overDiskQuotaChecker: overDiskQuotaChecker)
                
                sut.didSelectMenuAction(action)
                
                #expect(sut.sharedUIState.selectedDisplayActionEntity == expectedAction)
            }
        }
        
        @Suite("Quick Action")
        @MainActor
        struct QuickAction {
            @Test("when over disk quota reached for new playlist, should not set quick action entity",
                  arguments: [
                    (true, QuickActionEntity.download, Optional<QuickActionEntity>.none),
                    (true, QuickActionEntity.shareLink, Optional<QuickActionEntity>.none),
                    (true, QuickActionEntity.manageLink, Optional<QuickActionEntity>.none),
                    (true, QuickActionEntity.removeLink, Optional<QuickActionEntity>.none),
                    (true, QuickActionEntity.rename, Optional<QuickActionEntity>.none),
                    (true, QuickActionEntity.saveToPhotos, Optional<QuickActionEntity>.none),
                    (false, .download, .some(.download)),
                    (true, .sendToChat, .some(.sendToChat))]
            )
            func overDiskQuota(
                isPaywalled: Bool,
                action: QuickActionEntity,
                expectedAction: QuickActionEntity?
            ) {
                let overDiskQuotaChecker = MockOverDiskQuotaChecker(isPaywalled: isPaywalled)
                let sut = makeSUT(overDiskQuotaChecker: overDiskQuotaChecker)
                
                sut.didSelectQuickAction(action)
                
                #expect(sut.sharedUIState.selectedQuickActionEntity == expectedAction)
            }
        }
        
        @Suite("Video Action")
        @MainActor
        struct VideoAction {
            @Test("when over disk quota reached for new playlist, should not set video playlist action entity",
                  arguments: [
                    (false, VideoPlaylistActionEntity.addVideosToVideoPlaylistContent, Optional.some(VideoPlaylistActionEntity.addVideosToVideoPlaylistContent)),
                    (true, .addVideosToVideoPlaylistContent, .none),
                    (false, .delete, .some(VideoPlaylistActionEntity.delete)),
                    (true, .delete, .none)]
            )
            func overDiskQuota(
                isPaywalled: Bool,
                action: VideoPlaylistActionEntity,
                expectedAction: VideoPlaylistActionEntity?
            ) {
                let overDiskQuotaChecker = MockOverDiskQuotaChecker(isPaywalled: isPaywalled)
                let sut = makeSUT(overDiskQuotaChecker: overDiskQuotaChecker)
                
                sut.didSelectVideoPlaylistAction(action)
                
                #expect(sut.sharedUIState.selectedVideoPlaylistActionEntity == expectedAction)
            }
        }
    }
    
    @MainActor
    private static func makeSUT(
        sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol = MockSortOrderPreferenceUseCase(sortOrderEntity: .none),
        overDiskQuotaChecker: some OverDiskQuotaChecking = MockOverDiskQuotaChecker()
    ) -> VideoPlaylistContentContainerViewModel {
        .init(
            sortOrderPreferenceUseCase: sortOrderPreferenceUseCase,
            overDiskQuotaChecker: overDiskQuotaChecker
        )
    }
}
