@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import Testing

struct CameraUploadsSettingsViewModelTests {
    @Suite("Track analytics events")
    struct TestCUSettingsAnalyticsEvents {
        
        struct TestCaseData {
            var event: CUSettingsEvent
            var expectedEventIdentifier: any EventIdentifier
        }
        
        @Test(arguments: [
            TestCaseData(event: .cameraUploads(true), expectedEventIdentifier: CameraUploadsEnabledEvent()),
            TestCaseData(event: .cameraUploads(false), expectedEventIdentifier: CameraUploadsDisabledEvent()),
            
            TestCaseData(event: .videoUploads(true), expectedEventIdentifier: VideoUploadsEnabledEvent()),
            TestCaseData(event: .videoUploads(false), expectedEventIdentifier: VideoUploadsDisabledEvent()),
            
            TestCaseData(event: .cameraUploadsFormat(.HEIC), expectedEventIdentifier: CameraUploadsFormatHEICSelectedEvent()),
            TestCaseData(event: .cameraUploadsFormat(.JPG), expectedEventIdentifier: CameraUploadsFormatJPGSelectedEvent()),
            
            TestCaseData(event: .megaUploadFolderUpdated, expectedEventIdentifier: MegaUploadFolderUpdatedEvent()),
            
            TestCaseData(event: .photosLocationTags(true), expectedEventIdentifier: PhotosLocationTagsEnabledEvent()),
            TestCaseData(event: .photosLocationTags(false), expectedEventIdentifier: PhotosLocationTagsDisabledEvent()),
            
            TestCaseData(event: .cameraUploadsMobileData(true), expectedEventIdentifier: CameraUploadsMobileDataEnabledEvent()),
            TestCaseData(event: .cameraUploadsMobileData(false), expectedEventIdentifier: CameraUploadsMobileDataDisabledEvent())
        ])
        @MainActor func trackCorrectAnalyticsEvent(testCase: TestCaseData) {
            let tracker = MockTracker()
            let sut = CameraUploadsSettingsViewModel(tracker: tracker)
            sut.trackEvent(testCase.event)
            Test.assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [testCase.expectedEventIdentifier]
            )
        }
    }
}
