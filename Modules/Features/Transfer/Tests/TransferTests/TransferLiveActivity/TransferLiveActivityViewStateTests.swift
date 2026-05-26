import Testing
@testable import Transfer

struct TransferLiveActivityViewStateTests {

    // MARK: - isStale = false (pass-through)

    @Test
    func statusText_whenNotStale_matchesStateStatusText() {
        guard #available(iOS 16.2, *) else { return }
        let state = TransferLiveActivityAttributes.ContentState.fixture(statusText: "Uploading files")
        let sut = TransferLiveActivityViewState(state: state, isStale: false)

        #expect(sut.statusText == "Uploading files")
    }

    @Test
    func speed_whenNotStale_matchesFormattedSpeed() {
        guard #available(iOS 16.2, *) else { return }
        let state = TransferLiveActivityAttributes.ContentState.fixture(formattedSpeed: "3.4 MB/s")
        let sut = TransferLiveActivityViewState(state: state, isStale: false)

        #expect(sut.speed == "3.4 MB/s")
    }

    // MARK: - isStale = true (resolved)

    @Test
    func statusText_whenStale_isNotUnderlyingStatusText() {
        guard #available(iOS 16.2, *) else { return }
        let state = TransferLiveActivityAttributes.ContentState.fixture(statusText: "Uploading files")
        let sut = TransferLiveActivityViewState(state: state, isStale: true)

        #expect(sut.statusText != "Uploading files")
        #expect(!sut.statusText.isEmpty)
    }

    @Test
    func speed_whenStale_isEmpty() {
        guard #available(iOS 16.2, *) else { return }
        let state = TransferLiveActivityAttributes.ContentState.fixture(formattedSpeed: "3.4 MB/s")
        let sut = TransferLiveActivityViewState(state: state, isStale: true)

        #expect(sut.speed == "")
    }

    // MARK: - Pure pass-throughs (no isStale fork)

    @Test(arguments: [true, false])
    func progressFraction_passesThroughRegardlessOfStaleness(isStale: Bool) {
        guard #available(iOS 16.2, *) else { return }
        let state = TransferLiveActivityAttributes.ContentState.fixture(progressFraction: 0.42)
        let sut = TransferLiveActivityViewState(state: state, isStale: isStale)

        #expect(sut.progressFraction == 0.42)
    }

    @Test(arguments: [true, false])
    func percentageText_passesThroughRegardlessOfStaleness(isStale: Bool) {
        guard #available(iOS 16.2, *) else { return }
        let state = TransferLiveActivityAttributes.ContentState.fixture(percentageText: "42%")
        let sut = TransferLiveActivityViewState(state: state, isStale: isStale)

        #expect(sut.percentageText == "42%")
    }

    @Test(arguments: [true, false])
    func fileCountText_passesThroughRegardlessOfStaleness(isStale: Bool) {
        guard #available(iOS 16.2, *) else { return }
        let state = TransferLiveActivityAttributes.ContentState.fixture(fileCountText: "1 of 3")
        let sut = TransferLiveActivityViewState(state: state, isStale: isStale)

        #expect(sut.fileCountText == "1 of 3")
    }

    // MARK: - Accessibility composition

    @Test
    func accessibilityDescription_joinsNonEmptyFieldsWithComma() {
        guard #available(iOS 16.2, *) else { return }
        let state = TransferLiveActivityAttributes.ContentState.fixture(
            statusText: "Uploading files",
            percentageText: "42%",
            fileCountText: "1 of 3",
            formattedSpeed: "3.4 MB/s"
        )
        let sut = TransferLiveActivityViewState(state: state, isStale: false)

        #expect(sut.accessibilityDescription == "Uploading files, 42%, 1 of 3, 3.4 MB/s")
    }

    @Test
    func accessibilityDescription_skipsEmptyFields() {
        guard #available(iOS 16.2, *) else { return }
        let state = TransferLiveActivityAttributes.ContentState.fixture(
            statusText: "Paused",
            percentageText: "42%",
            fileCountText: "1 of 3",
            formattedSpeed: ""
        )
        let sut = TransferLiveActivityViewState(state: state, isStale: false)

        #expect(sut.accessibilityDescription == "Paused, 42%, 1 of 3")
    }

    @Test
    func accessibilityDescription_whenStale_dropsSpeed() {
        guard #available(iOS 16.2, *) else { return }
        let state = TransferLiveActivityAttributes.ContentState.fixture(
            percentageText: "42%",
            fileCountText: "1 of 3",
            formattedSpeed: "3.4 MB/s"
        )
        let sut = TransferLiveActivityViewState(state: state, isStale: true)

        #expect(sut.accessibilityDescription.contains("3.4 MB/s") == false)
        #expect(sut.accessibilityDescription.contains("42%"))
        #expect(sut.accessibilityDescription.contains("1 of 3"))
    }

    @Test
    func compactAccessibilityDescription_includesStatusAndPercentageOnly() {
        guard #available(iOS 16.2, *) else { return }
        let state = TransferLiveActivityAttributes.ContentState.fixture(
            statusText: "Uploading files",
            percentageText: "42%",
            fileCountText: "1 of 3",
            formattedSpeed: "3.4 MB/s"
        )
        let sut = TransferLiveActivityViewState(state: state, isStale: false)

        #expect(sut.compactAccessibilityDescription == "Uploading files, 42%")
    }
}
