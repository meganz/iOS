import Testing
@testable import Transfer

@Suite("TransfersListViewModel More menu")
@MainActor
struct TransfersListViewModelTests {

    // MARK: - Active

    @Test func activeTab_withRows_offersSelectAndCancelAll() {
        let sut = TransfersListViewModel(hasActiveTransfers: true)
        sut.selectedTab = .active

        #expect(sut.menuActions == [.select, .cancelAll])
        #expect(sut.showsMoreMenu)
    }

    @Test func activeTab_withoutRows_hidesMoreMenu() {
        let sut = TransfersListViewModel(hasActiveTransfers: false)
        sut.selectedTab = .active

        #expect(sut.menuActions.isEmpty)
        #expect(!sut.showsMoreMenu)
    }

    // MARK: - Completed

    @Test func completedTab_withRows_offersSelectAndClearAll() {
        let sut = TransfersListViewModel(hasCompletedTransfers: true)
        sut.selectedTab = .completed

        #expect(sut.menuActions == [.select, .clearAll])
        #expect(sut.showsMoreMenu)
    }

    @Test func completedTab_withoutRows_hidesMoreMenu() {
        let sut = TransfersListViewModel(hasCompletedTransfers: false)
        sut.selectedTab = .completed

        #expect(sut.menuActions.isEmpty)
        #expect(!sut.showsMoreMenu)
    }

    // MARK: - Failed

    @Test func failedTab_withRows_offersSelectRetryAllAndClearAll() {
        let sut = TransfersListViewModel(hasFailedTransfers: true)
        sut.selectedTab = .failed

        #expect(sut.menuActions == [.select, .retryAll, .clearAll])
        #expect(sut.showsMoreMenu)
    }

    @Test func failedTab_withoutRows_hidesMoreMenu() {
        let sut = TransfersListViewModel(hasFailedTransfers: false)
        sut.selectedTab = .failed

        #expect(sut.menuActions.isEmpty)
        #expect(!sut.showsMoreMenu)
    }

    // MARK: - Menu reads only the selected tab

    @Test func menu_readsOnlyTheSelectedTabState() {
        let sut = TransfersListViewModel(
            hasActiveTransfers: false,
            hasCompletedTransfers: true,
            hasFailedTransfers: true
        )

        // Active is empty even though other tabs have rows.
        sut.selectedTab = .active
        #expect(sut.menuActions.isEmpty)

        sut.selectedTab = .completed
        #expect(sut.menuActions == [.select, .clearAll])
    }
}
