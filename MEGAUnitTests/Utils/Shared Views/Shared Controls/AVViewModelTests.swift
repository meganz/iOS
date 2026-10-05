@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import Testing
import XCTest

final class AVViewModelTests: XCTestCase {

    func testOnViewDidLoad_called_shouldTrackPhotoPreviewEvent() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        
        sut.onViewDidLoad()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [VideoPlayerScreenEvent()])
    }

    private func makeSUT(
        tracker: some AnalyticsTracking = MockTracker()
    ) -> AVViewModel {
        AVViewModel(tracker: tracker)
    }
}

@Suite("AVViewModel continue where you left off")
struct AVViewModelLeftOffItemTests {

    @Test("recording stores the handle and name")
    func processLeftOffItem_whenShouldRecord_shouldRecord() async {
        let recordUseCase = MockLeftOffItemRecordUseCase()
        let sut = makeSUT(leftOffItemRecordUseCase: recordUseCase)

        sut.processLeftOffItem(handle: 42, name: "video.mp4", shouldRecord: true)
        await sut.leftOffItemTask?.value

        #expect(recordUseCase.record_Calls.map(\.handle) == [42])
        #expect(recordUseCase.record_Calls.map(\.name) == ["video.mp4"])
        #expect(recordUseCase.remove_Calls.isEmpty)
    }

    @Test("not recording removes the handle")
    func processLeftOffItem_whenShouldNotRecord_shouldRemove() async {
        let recordUseCase = MockLeftOffItemRecordUseCase()
        let sut = makeSUT(leftOffItemRecordUseCase: recordUseCase)

        sut.processLeftOffItem(handle: 42, name: "video.mp4", shouldRecord: false)
        await sut.leftOffItemTask?.value

        #expect(recordUseCase.remove_Calls == [42])
        #expect(recordUseCase.record_Calls.isEmpty)
    }

    @Test("a nil name cannot be recorded, so nothing is stored")
    func processLeftOffItem_whenRecordingWithoutName_shouldDoNothing() async {
        let recordUseCase = MockLeftOffItemRecordUseCase()
        let sut = makeSUT(leftOffItemRecordUseCase: recordUseCase)

        sut.processLeftOffItem(handle: 42, name: nil, shouldRecord: true)
        await sut.leftOffItemTask?.value

        #expect(recordUseCase.record_Calls.isEmpty)
        #expect(recordUseCase.remove_Calls.isEmpty)
    }

    @Test("removal does not need a name")
    func processLeftOffItem_whenRemovingWithoutName_shouldRemove() async {
        let recordUseCase = MockLeftOffItemRecordUseCase()
        let sut = makeSUT(leftOffItemRecordUseCase: recordUseCase)

        sut.processLeftOffItem(handle: 42, name: nil, shouldRecord: false)
        await sut.leftOffItemTask?.value

        #expect(recordUseCase.remove_Calls == [42])
    }

    private func makeSUT(
        leftOffItemRecordUseCase: some LeftOffItemRecordUseCaseProtocol = MockLeftOffItemRecordUseCase()
    ) -> AVViewModel {
        AVViewModel(tracker: MockTracker(), leftOffItemRecordUseCase: leftOffItemRecordUseCase)
    }
}
