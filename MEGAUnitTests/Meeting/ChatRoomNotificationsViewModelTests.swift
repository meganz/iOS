@testable import MEGA
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGASwift
import XCTest

final class ChatRoomNotificationsViewModelTests: XCTestCase {

    /// Changing the setting writes it to the API, and offline that request never completes, so the
    /// screen used to sit on a progress indicator forever.
    @MainActor
    func testIsChatNotificationsToggleEnabled_whenOffline_isFalse() {
        let sut = makeSUT(isConnected: false, isNewOfflineModeEnabled: true)

        XCTAssertFalse(sut.isChatNotificationsToggleEnabled)
    }

    @MainActor
    func testIsChatNotificationsToggleEnabled_whenOnline_isTrue() {
        let sut = makeSUT(isConnected: true, isNewOfflineModeEnabled: true)

        XCTAssertTrue(sut.isChatNotificationsToggleEnabled)
    }

    @MainActor
    func testIsChatNotificationsToggleEnabled_whenOfflineModeDisabled_isTrue() {
        let sut = makeSUT(isConnected: false, isNewOfflineModeEnabled: false)

        XCTAssertTrue(sut.isChatNotificationsToggleEnabled)
    }

    @MainActor
    func testNoConnectionMessage_whenOffline_explainsWhyTheToggleIsDisabled() {
        let sut = makeSUT(isConnected: false, isNewOfflineModeEnabled: true)

        XCTAssertEqual(sut.noConnectionMessage, Strings.Localizable.noInternetConnection)
    }

    @MainActor
    func testNoConnectionMessage_whenOnline_isNotShown() {
        let sut = makeSUT(isConnected: true, isNewOfflineModeEnabled: true)

        XCTAssertNil(sut.noConnectionMessage)
    }

    @MainActor
    func testIsChatNotificationsToggleEnabled_whenTheConnectionComesBack_becomesTrue() async {
        let sut = makeSUT(
            isConnected: false,
            isNewOfflineModeEnabled: true,
            connectionSequence: AsyncStream { continuation in
                continuation.yield(true)
                continuation.finish()
            }.eraseToAnyAsyncSequence()
        )

        let predicate = NSPredicate { _, _ in sut.isChatNotificationsToggleEnabled }
        await fulfillment(of: [expectation(for: predicate, evaluatedWith: nil)], timeout: 6)
    }

    // MARK: - Helpers

    @MainActor
    private func makeSUT(
        isConnected: Bool,
        isNewOfflineModeEnabled: Bool,
        connectionSequence: AnyAsyncSequence<Bool> = EmptyAsyncSequence().eraseToAnyAsyncSequence()
    ) -> ChatRoomNotificationsViewModel {
        ChatRoomNotificationsViewModel(
            chatRoom: ChatRoomEntity(chatId: 1),
            networkMonitorUseCase: MockNetworkMonitorUseCase(
                connected: isConnected,
                connectionSequence: connectionSequence
            ),
            featureFlagProvider: MockFeatureFlagProvider(list: [.offlineMode: isNewOfflineModeEnabled])
        )
    }
}
