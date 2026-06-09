@testable import MEGA
@preconcurrency import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomainMock
import Testing

struct CameraUploadsAdvancedOptionsViewModelTests {
    @Suite("Track analytics events")
    struct TestCameraUploadsAnalyticsEvents {
        
        struct TestCaseData: Sendable {
            let event: CameraUploadsAdvancedOptionsEvent
            let expectedEventIdentifier: any EventIdentifier
        }
        
        @Test(arguments: [
            TestCaseData(event: .livePhotoVideoUploads(true), expectedEventIdentifier: LivePhotoVideoUploadsEnabledEvent()),
            TestCaseData(event: .livePhotoVideoUploads(false), expectedEventIdentifier: LivePhotoVideoUploadsDisabledEvent()),
            
            TestCaseData(event: .burstPhotosUpload(true), expectedEventIdentifier: BurstPhotosUploadEnabledEvent()),
            TestCaseData(event: .burstPhotosUpload(false), expectedEventIdentifier: BurstPhotosUploadDisabledEvent()),
            
            TestCaseData(event: .hiddenAlbumUpload(true), expectedEventIdentifier: HiddenAlbumUploadEnabledEvent()),
            TestCaseData(event: .hiddenAlbumUpload(false), expectedEventIdentifier: HiddenAlbumUploadDisabledEvent()),
            
            TestCaseData(event: .sharedAlbumsUpload(true), expectedEventIdentifier: SharedAlbumsUploadEnabledEvent()),
            TestCaseData(event: .sharedAlbumsUpload(false), expectedEventIdentifier: SharedAlbumsUploadDisabledEvent()),
            
            TestCaseData(event: .iTunesSyncedAlbumsUpload(true), expectedEventIdentifier: ITunesSyncedAlbumsUploadEnabledEvent()),
            TestCaseData(event: .iTunesSyncedAlbumsUpload(false), expectedEventIdentifier: ITunesSyncedAlbumsUploadDisabledEvent())
        ])
        @MainActor func trackCorrectAnalyticsEvent(testCase: TestCaseData) {
            let tracker = MockTracker()
            let sut = CameraUploadsAdvancedOptionsViewModel(tracker: tracker)
            
            sut.trackEvent(testCase.event)
            
            Test.assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [testCase.expectedEventIdentifier]
            )
        }
    }

    @Suite("Upload only new photos option visibility")
    struct UploadOnlyNewPhotosOptionVisibility {
        private func makeSUT(featureFlagEnabled: Bool) -> CameraUploadsAdvancedOptionsViewModel {
            CameraUploadsAdvancedOptionsViewModel(
                remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.iosUploadOnlyNewPhotos: featureFlagEnabled])
            )
        }

        @Test func shownWhenFeatureFlagOn() {
            #expect(makeSUT(featureFlagEnabled: true).shouldShowUploadOnlyNewPhotosOption)
        }

        @Test func hiddenWhenFeatureFlagOff() {
            #expect(makeSUT(featureFlagEnabled: false).shouldShowUploadOnlyNewPhotosOption == false)
        }
    }
}
