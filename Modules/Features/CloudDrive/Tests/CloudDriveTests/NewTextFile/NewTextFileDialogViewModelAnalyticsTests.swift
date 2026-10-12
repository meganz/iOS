@testable import CloudDrive
import MEGAAnalyticsiOS
import MEGAAppPresentationMock
import Testing

@MainActor
struct NewTextFileDialogViewModelAnalyticsTests {
    private final class Calls {
        var created: [String] = []
        var cancelCount = 0
        var trackedCountWhenCreated: [Int] = []
        var closesDialog = true
    }

    private static let richName = String(describing: RichTextFileCreatedEvent.self)
    private static let plainName = String(describing: PlainTextFileCreatedEvent.self)

    private func makeSUT(
        tracker: MockTracker,
        calls: Calls = Calls()
    ) -> NewTextFileDialogViewModel {
        NewTextFileDialogViewModel(
            tracker: tracker,
            onCreate: {
                calls.created.append($0)
                calls.trackedCountWhenCreated.append(tracker.trackedEventIdentifiers.count)
                return calls.closesDialog
            },
            onCancel: { calls.cancelCount += 1 }
        )
    }

    private func trackedNames(_ tracker: MockTracker) -> [String] {
        tracker.trackedEventIdentifiers.map { String(describing: type(of: $0)) }
    }

    @Test func createWithMarkdownNameTracksRichTextFileCreatedEventOnce() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        sut.setFileName("notes.md")

        sut.didTapCreate()

        #expect(trackedNames(tracker) == [Self.richName])
    }

    @Test func createWithTxtNameTracksPlainTextFileCreatedEventOnce() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        sut.setFileName("notes.txt")

        sut.didTapCreate()

        #expect(trackedNames(tracker) == [Self.plainName])
    }

    @Test func createWithoutExtensionTracksPlainTextFileCreatedEvent() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        sut.setFileName("notes")

        sut.didTapCreate()

        #expect(trackedNames(tracker) == [Self.plainName])
    }

    @Test func createWithUppercaseMarkdownExtensionTracksRichTextFileCreatedEvent() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        sut.setFileName("notes.MD")

        sut.didTapCreate()

        #expect(trackedNames(tracker) == [Self.richName])
    }

    @Test func createWithMarkdownLongExtensionTracksRichTextFileCreatedEvent() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        sut.setFileName("notes.markdown")

        sut.didTapCreate()

        #expect(trackedNames(tracker) == [Self.richName])
    }

    @Test func createWithSpacesAroundMarkdownNameTracksRichTextFileCreatedEvent() {
        let tracker = MockTracker()
        let calls = Calls()
        let sut = makeSUT(tracker: tracker, calls: calls)
        sut.setFileName(" notes.md ")

        sut.didTapCreate()

        #expect(trackedNames(tracker) == [Self.richName])
        #expect(calls.created == ["notes.md"])
    }

    @Test func createWithInvalidNameTracksNoEventAndDoesNotCreate() {
        let tracker = MockTracker()
        let calls = Calls()
        let sut = makeSUT(tracker: tracker, calls: calls)
        sut.setFileName("a/b.md")

        sut.didTapCreate()

        #expect(tracker.trackedEventIdentifiers.isEmpty)
        #expect(calls.created.isEmpty)
    }

    @Test func createWithBlankNameTracksNoEvent() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        sut.setFileName("   ")

        sut.didTapCreate()

        #expect(tracker.trackedEventIdentifiers.isEmpty)
    }

    @Test func submitWithValidNameTracksOneEvent() {
        let tracker = MockTracker()
        let calls = Calls()
        let sut = makeSUT(tracker: tracker, calls: calls)
        sut.setFileName("notes.md")

        sut.didSubmit()

        #expect(trackedNames(tracker) == [Self.richName])
        #expect(calls.created == ["notes.md"])
    }

    @Test func createTracksEventAfterOnCreateClosesDialog() {
        let tracker = MockTracker()
        let calls = Calls()
        let sut = makeSUT(tracker: tracker, calls: calls)
        sut.setFileName("notes.txt")

        sut.didTapCreate()

        #expect(calls.trackedCountWhenCreated == [0])
        #expect(trackedNames(tracker) == [Self.plainName])
    }

    @Test func createThatKeepsDialogOpenTracksNoEvent() {
        let tracker = MockTracker()
        let calls = Calls()
        calls.closesDialog = false
        let sut = makeSUT(tracker: tracker, calls: calls)
        sut.setFileName("notes.md")

        sut.didTapCreate()
        sut.didTapCreate()

        #expect(calls.created == ["notes.md", "notes.md"])
        #expect(tracker.trackedEventIdentifiers.isEmpty)
    }

    @Test func createAfterOfflineTapsTracksOneEvent() {
        let tracker = MockTracker()
        let calls = Calls()
        calls.closesDialog = false
        let sut = makeSUT(tracker: tracker, calls: calls)
        sut.setFileName("notes.md")

        sut.didTapCreate()
        sut.didTapCreate()
        calls.closesDialog = true
        sut.didTapCreate()

        #expect(trackedNames(tracker) == [Self.richName])
    }

    @Test func editingAndCancelTrackNoEvent() {
        let tracker = MockTracker()
        let calls = Calls()
        let sut = makeSUT(tracker: tracker, calls: calls)

        sut.setFileName("notes.md")
        sut.isRichTextChecked = false
        sut.isRichTextChecked = true
        sut.didTapCancel()

        #expect(tracker.trackedEventIdentifiers.isEmpty)
        #expect(calls.cancelCount == 1)
    }
}
