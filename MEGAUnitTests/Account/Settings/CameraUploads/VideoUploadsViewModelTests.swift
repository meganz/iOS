@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import Testing

struct VideoUploadsViewModelTests {
    @Suite("Track analytics events")
    struct TestVideoUploadsAnalyticsEvents {
        
        struct TestCaseData {
            let event: VideoUploadsEvents
            let expectedEventIdentifier: any EventIdentifier
        }
        
        @Test(arguments: [
            TestCaseData(event: .videoUploads(true), expectedEventIdentifier: VideoUploadsEnabledEvent()),
            TestCaseData(event: .videoUploads(false), expectedEventIdentifier: VideoUploadsDisabledEvent()),
            
            TestCaseData(event: .videoCodec(.HEVC), expectedEventIdentifier: VideoCodecHEVCSelectedEvent()),
            TestCaseData(event: .videoCodec(.H264), expectedEventIdentifier: VideoCodecH264SelectedEvent()),
            
            TestCaseData(event: .videoQuality(.low), expectedEventIdentifier: VideoQualityLowEvent()),
            TestCaseData(event: .videoQuality(.medium), expectedEventIdentifier: VideoQualityMediumEvent()),
            TestCaseData(event: .videoQuality(.high), expectedEventIdentifier: VideoQualityHighEvent()),
            TestCaseData(event: .videoQuality(.original), expectedEventIdentifier: VideoQualityOriginalEvent())
        ])
        @MainActor func trackCorrectAnalyticsEvent(testCase: TestCaseData) {
            let tracker = MockTracker()
            let sut = VideoUploadsViewModel(tracker: tracker)
            
            sut.trackEvent(testCase.event)
            
            Test.assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [testCase.expectedEventIdentifier]
            )
        }
    }
}
