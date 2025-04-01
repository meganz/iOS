@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGATest
import XCTest

final class CustomModalAlertViewModelTests: XCTestCase {
    func testOnViewDidLoad_analyticsEvents_shouldTrackCorrectly() {
        let dialogEvent = MockDialogEvent()
        let events: [CustomModalAlertViewModel.CustomModalAlertViewAnalyticEvents?] = [
            .init(dialogDisplayedEventIdentifier: dialogEvent,
                  fistButtonPressedEventIdentifier: nil),
            nil]
        
        for (index, event) in events.enumerated() {
            let tracker = MockTracker()
            let sut = makeSUT(tracker: tracker,
                              analyticsEvents: event)
            
            sut.onViewDidLoad()
            
            assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [event?.dialogDisplayedEventIdentifier].compactMap { $0 },
                message: "Failed at index: \(index) with event: \(event?.dialogDisplayedEventIdentifier?.eventName ?? "")"
            )
        }
    }
    
    func testFirstButtonTapped_analyticsEvents_shouldTrackCorrectly() {
        let buttonEvent = MockButtonPressedEvent()
        let events: [CustomModalAlertViewModel.CustomModalAlertViewAnalyticEvents?] = [
            .init(dialogDisplayedEventIdentifier: nil,
                  fistButtonPressedEventIdentifier: buttonEvent),
            nil]
        
        for (index, event) in events.enumerated() {
            let tracker = MockTracker()
            let sut = makeSUT(tracker: tracker,
                              analyticsEvents: event)
            
            sut.firstButtonTapped()
            
            assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [event?.fistButtonPressedEventIdentifier].compactMap { $0 },
                message: "Failed at index: \(index) with event: \(event?.fistButtonPressedEventIdentifier?.eventName ?? "")"
            )
        }
    }
    
    private func makeSUT(tracker: some AnalyticsTracking = MockTracker(),
                         analyticsEvents: CustomModalAlertViewModel.CustomModalAlertViewAnalyticEvents? = nil,
                         file: StaticString = #file,
                         line: UInt = #line) -> CustomModalAlertViewModel {
        let sut = CustomModalAlertViewModel(tracker: tracker,
                                  analyticsEvents: analyticsEvents)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}

private class MockDialogEvent: DialogDisplayedEventIdentifier {
    let dialogName: String = "Mock Dialog"
    let screenName: String? = "Mock Dialog"
    let eventName: String = "Mock Dialog Event"
    let uniqueIdentifier: Int32 = Int32.random(in: 0...100)
}

private class MockButtonPressedEvent: ButtonPressedEventIdentifier {
    let buttonName: String = "Mock Button"
    let dialogName: String? = "Mock Button"
    let screenName: String? = "Mock Screen"
    let eventName: String = "Mock Button Pressed Event"
    let uniqueIdentifier: Int32 = Int32.random(in: 0...100)
}
