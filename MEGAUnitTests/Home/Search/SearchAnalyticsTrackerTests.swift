@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGATest
import Search
import Testing

@Suite("SearchAnalyticsTracker Tests")
struct SearchAnalyticsTrackerTests {
    @Test("Track images chip tapped when selected")
    func trackImagesChipTapped() {
        let tracker = MockTracker()
        let sut = SearchAnalyticsTracker(tracker: tracker)

        sut.trackChipTapped(SearchChipEntity.images, selected: true)

        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [SearchImageFilterPressedEvent()]
        )
    }

    @Test("Track docs chip tapped when selected")
    func trackDocsChipTapped() {
        let tracker = MockTracker()
        let sut = SearchAnalyticsTracker(tracker: tracker)

        sut.trackChipTapped(SearchChipEntity.docs, selected: true)

        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [SearchDocsFilterPressedEvent()]
        )
    }

    @Test("Track audio chip tapped when selected")
    func trackAudioChipTapped() {
        let tracker = MockTracker()
        let sut = SearchAnalyticsTracker(tracker: tracker)

        sut.trackChipTapped(SearchChipEntity.audio, selected: true)

        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [SearchAudioFilterPressedEvent()]
        )
    }

    @Test("Track video chip tapped when selected")
    func trackVideoChipTapped() {
        let tracker = MockTracker()
        let sut = SearchAnalyticsTracker(tracker: tracker)

        sut.trackChipTapped(SearchChipEntity.video, selected: true)

        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [SearchVideosFilterPressedEvent()]
        )
    }

    @Test("Track node formats group chip tapped when selected")
    func trackNodeFormatsGroupChipTapped() {
        let tracker = MockTracker()
        let sut = SearchAnalyticsTracker(tracker: tracker)

        sut.trackChipTapped(SearchChipEntity.nodeFormatsGroupedChip, selected: true)

        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [SearchFileTypeDropdownChipPressedEvent()]
        )
    }

    @Test("Track reset filter event when chip is deselected")
    func trackResetFilterWhenDeselected() {
        let tracker = MockTracker()
        let sut = SearchAnalyticsTracker(tracker: tracker)

        sut.trackChipTapped(SearchChipEntity.images, selected: false)

        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [SearchResetFilterPressedEvent()]
        )
    }

    @Test("Track last 7 days chip tapped when selected")
    func trackLast7DaysChipTapped() {
        let tracker = MockTracker()
        let sut = SearchAnalyticsTracker(tracker: tracker)
        let chip = SearchChipEntity.last7Days(calendar: .current, currentDate: Date())

        sut.trackChipTapped(chip, selected: true)

        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [SearchLastModifiedLastSevenDaysClickedEvent()]
        )
    }

    @Test("Track last 30 days chip tapped when selected")
    func trackLast30DaysChipTapped() {
        let tracker = MockTracker()
        let sut = SearchAnalyticsTracker(tracker: tracker)
        let chip = SearchChipEntity.last30Days(calendar: .current, currentDate: Date())

        sut.trackChipTapped(chip, selected: true)

        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [SearchLastModifiedLastThirtyDaysClickedEvent()]
        )
    }

    @Test("Track this year chip tapped when selected")
    func trackThisYearChipTapped() {
        let tracker = MockTracker()
        let sut = SearchAnalyticsTracker(tracker: tracker)
        let chip = SearchChipEntity.thisYear(calendar: .current, currentDate: Date())

        sut.trackChipTapped(chip, selected: true)

        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [SearchLastModifiedThisYearClickedEvent()]
        )
    }

    @Test("Track last year chip tapped when selected")
    func trackLastYearChipTapped() {
        let tracker = MockTracker()
        let sut = SearchAnalyticsTracker(tracker: tracker)
        let chip = SearchChipEntity.lastYear(currentDate: Date())

        sut.trackChipTapped(chip, selected: true)

        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [SearchLastModifiedLastYearClickedEvent()]
        )
    }

    @Test("Track older chip tapped when selected")
    func trackOlderChipTapped() {
        let tracker = MockTracker()
        let sut = SearchAnalyticsTracker(tracker: tracker)
        let chip = SearchChipEntity.older(currentDate: Date())

        sut.trackChipTapped(chip, selected: true)

        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [SearchLastModifiedOlderClickedEvent()]
        )
    }

    @Test("Track chip picker show for node formats group")
    func trackChipPickerShowForNodeFormatsGroup() {
        let tracker = MockTracker()
        let sut = SearchAnalyticsTracker(tracker: tracker)

        sut.trackChipPickerShow(SearchChipEntity.nodeFormatsGroupedChip)

        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [SearchFileTypeDropdownChipPressedEvent()]
        )
    }

    @Test("Track chip picker show does not track for chip without analytics event")
    func trackChipPickerShowNoEventForUnknownChip() {
        let tracker = MockTracker()
        let sut = SearchAnalyticsTracker(tracker: tracker)
        let unknownChip = SearchChipEntity(type: .nodeFormat(.photo), title: "Unknown")

        sut.trackChipPickerShow(unknownChip)

        #expect(tracker.trackedEventIdentifiers.isEmpty)
    }

    @Test("Track result context menu tapped")
    func trackResultContextMenuTapped() {
        let tracker = MockTracker()
        let sut = SearchAnalyticsTracker(tracker: tracker)

        sut.trackResultContextMenuTapped()

        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [CloudDriveChildNodeMoreButtonPressedEvent()]
        )
    }
}
