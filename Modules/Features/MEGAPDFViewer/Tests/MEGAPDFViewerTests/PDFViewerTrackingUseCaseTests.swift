import MEGAAnalyticsiOS
import MEGAAppPresentationMock
@testable import MEGAPDFViewer
import Testing

struct PDFViewerTrackingUseCaseTests {
    @Test func localExport_payloadInitializersExposeOnlyApprovedKeys() {
        let failure = PdfViewerLoadFailedEvent(reason: "download_failed")
        let download = PdfViewerDownloadRequestedEvent(source: "offline")
        let action = PdfViewerMoreActionSelectedEvent(action: "add_to_cloud_drive", source: "file_link")

        #expect(Set(failure.info.keys) == ["reason"])
        #expect(failure.info["reason"] as? String == "download_failed")
        #expect(Set(download.info.keys) == ["source"])
        #expect(download.info["source"] as? String == "offline")
        #expect(Set(action.info.keys) == ["action", "source"])
        #expect(action.info["action"] as? String == "add_to_cloud_drive")
        #expect(action.info["source"] as? String == "file_link")
    }

    @Test(arguments: [
        PDFViewerAnalyticsEvent.screenPresented, .closed, .loadSucceeded,
        .passwordUnlocked, .moreMenuOpened, .thumbnailsOpened,
        .thumbnailSelected, .contentsOpened, .contentsItemSelected,
        .searchToolbarSelected, .searchSessionStarted, .searchResultItemSelected,
        .offlineFileOpened
    ])
    func track_emitsExactlyOneExpectedEvent(event: PDFViewerAnalyticsEvent) {
        let tracker = MockTracker()
        let sut = PDFViewerTrackingUseCase(tracker: tracker)
        let expected: (any EventIdentifier)? = switch event {
        case .screenPresented: PdfViewerScreenEvent()
        case .closed: PdfViewerClosedEvent()
        case .loadSucceeded: PdfViewerLoadSucceededEvent()
        case .passwordUnlocked: PdfViewerPasswordUnlockedEvent()
        case .moreMenuOpened: PdfViewerMoreMenuOpenedEvent()
        case .thumbnailsOpened: PdfViewerThumbnailsOpenedEvent()
        case .thumbnailSelected: PdfViewerThumbnailSelectedEvent()
        case .contentsOpened: PdfViewerContentsOpenedEvent()
        case .contentsItemSelected: PdfViewerContentsItemSelectedEvent()
        case .searchToolbarSelected: PdfViewerSearchMenuToolbarEvent()
        case .searchSessionStarted: PdfViewerSearchSessionStartedEvent()
        case .searchResultItemSelected: PdfViewerSearchResultItemSelectedEvent()
        case .offlineFileOpened: FileOpenEvent(fileType: "pdf", context: .offline)
        default: nil
        }
        guard let expected else {
            Issue.record("Missing event fixture")
            return
        }

        sut.track(event)

        #expect(tracker.trackedEventIdentifiers.count == 1)
        #expect(tracker.trackedEventIdentifiers.first.map {
            String(describing: type(of: $0))
        } == String(describing: type(of: expected)))
        if case .offlineFileOpened = event {
            let actual = tracker.trackedEventIdentifiers.first as? FileOpenEvent
            #expect(actual?.info["fileType"] as? String == "pdf")
            #expect(actual?.info["context"] as? FileOpen.FileOpenContext == .offline)
        }
    }

    @Test(arguments: PDFViewerAnalyticsFailure.allCases)
    func loadFailure_emitsOnlyBoundedReason(reason: PDFViewerAnalyticsFailure) {
        let tracker = MockTracker()
        let sut = PDFViewerTrackingUseCase(tracker: tracker)

        sut.track(.loadFailed(reason))

        #expect(tracker.trackedEventIdentifiers.count == 1)
        let actual = tracker.trackedEventIdentifiers.first as? PdfViewerLoadFailedEvent
        #expect(actual?.info["reason"] as? String == reason.rawValue)
    }

    @Test(arguments: PDFViewerAnalyticsSource.allCases)
    func downloadRequest_preservesExplicitSource(source: PDFViewerAnalyticsSource) {
        let tracker = MockTracker()
        let sut = PDFViewerTrackingUseCase(tracker: tracker)

        sut.track(.downloadRequested(source))

        #expect(tracker.trackedEventIdentifiers.count == 1)
        let actual = tracker.trackedEventIdentifiers.first as? PdfViewerDownloadRequestedEvent
        #expect(actual?.info["source"] as? String == source.rawValue)
    }

    @Test(arguments: PDFViewerAnalyticsMoreAction.allCases, PDFViewerAnalyticsSource.allCases)
    func moreAction_emitsBoundedActionAndSource(
        action: PDFViewerAnalyticsMoreAction, source: PDFViewerAnalyticsSource
    ) {
        let tracker = MockTracker()
        let sut = PDFViewerTrackingUseCase(tracker: tracker)

        sut.track(.moreActionSelected(action, source))

        #expect(tracker.trackedEventIdentifiers.count == 1)
        let actual = tracker.trackedEventIdentifiers.first as? PdfViewerMoreActionSelectedEvent
        #expect(actual?.info["action"] as? String == action.rawValue)
        #expect(actual?.info["source"] as? String == source.rawValue)
    }
}
