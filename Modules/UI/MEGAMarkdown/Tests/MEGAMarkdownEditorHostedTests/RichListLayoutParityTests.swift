import MEGAMarkdown
@testable import MEGAMarkdownEditor
import Testing
import UIKit

// Needs the iOS simulator. After an edit, a list that was updated row by row must have the same item heights
// as the same list read again from the model.
@MainActor
@Suite(.serialized, .hostedUI, .timeLimit(.minutes(1)))
struct RichListLayoutParityTests {
    nonisolated fileprivate static let tasks = "- [ ] one\n- [ ] two\n- [ ] three\n- [ ] four\n\nParagraph\n\n- bullet\n"
    nonisolated fileprivate static let ordered = "1. a\n2. b\n3. c\n4. d\n\nText\n"
    nonisolated fileprivate static let quotes = "> a\n> b\n\nText\n"

    enum Scenario: CaseIterable, CustomTestStringConvertible {
        case deleteLastTaskItem
        case deleteMiddleTaskItem
        case returnInATaskItem
        case enterTwiceAtTheEndOfATaskItem
        case enterOnAnEmptyTaskItemAsTyped
        case enterOnAnEmptyQuoteAsTyped
        case toggleACheckbox
        case indentATaskItem
        case deleteAnOrderedItem

        var testDescription: String { String(describing: self) }

        var markdown: String {
            switch self {
            case .enterOnAnEmptyQuoteAsTyped: RichListLayoutParityTests.quotes
            case .deleteAnOrderedItem: RichListLayoutParityTests.ordered
            default: RichListLayoutParityTests.tasks
            }
        }

        /// The caret to start from: row and offset.
        var start: (row: Int, offset: Int) {
            switch self {
            case .deleteLastTaskItem, .enterTwiceAtTheEndOfATaskItem, .enterOnAnEmptyTaskItemAsTyped: (3, 4)
            case .deleteMiddleTaskItem, .returnInATaskItem: (1, 3)
            case .enterOnAnEmptyQuoteAsTyped: (1, 1)
            case .toggleACheckbox, .indentATaskItem: (1, 0)
            case .deleteAnOrderedItem: (1, 1)
            }
        }

        /// One user action each. The test lets the list settle between them, like separate key presses.
        var steps: [@MainActor (RichEditorModel) -> Void] {
            let back: @MainActor (RichEditorModel) -> Void = { $0.deleteBackward() }
            let enter: @MainActor (RichEditorModel) -> Void = { $0.insertParagraphBreak() }
            switch self {
            case .deleteLastTaskItem, .deleteMiddleTaskItem: return Array(repeating: back, count: 5)
            case .returnInATaskItem: return [enter]
            case .enterTwiceAtTheEndOfATaskItem: return [enter, enter]
            // The text view sends Enter as typed text, so the plan sees a typing change.
            case .enterOnAnEmptyTaskItemAsTyped: return [enter, { $0.replaceText(inRow: 4, range: 0..<0, with: "\n") }]
            case .enterOnAnEmptyQuoteAsTyped: return [enter, { $0.replaceText(inRow: 2, range: 0..<0, with: "\n") }]
            case .toggleACheckbox: return [{ $0.toggleCheckbox(inRow: 1) }]
            case .indentATaskItem: return [{ $0.apply(.indent) }]
            case .deleteAnOrderedItem: return [back, back, back]
            }
        }

        /// A row that stepped out of its list or quote. It must draw no marker and no bar.
        var plainRow: Int? {
            switch self {
            case .enterOnAnEmptyTaskItemAsTyped: 4
            case .enterOnAnEmptyQuoteAsTyped: 2
            default: nil
            }
        }
    }

    private func heights(_ harness: RichListHarness) -> [CGFloat] {
        (0..<harness.list.itemCount).map { harness.list.itemFrame(at: $0).height }
    }

    @Test(arguments: Scenario.allCases)
    func updatedRowsHaveTheHeightsOfAFreshRead(scenario: Scenario) async throws {
        let harness = try RichListHarness(scenario.markdown)
        defer { harness.close() }
        harness.focus(row: scenario.start.row, caret: scenario.start.offset)
        try await harness.waitUntil { harness.focusedTextView != nil }
        for step in scenario.steps {
            step(harness.model)
            // No forced layout pass: the list sizes its cells in its own display pass, like in the app.
            try await Task.sleep(for: .milliseconds(80))
        }
        try await Task.sleep(for: .milliseconds(150))
        if let row = scenario.plainRow {
            #expect(harness.adapter.chrome[row].decorations.isEmpty, "row \(row) still has \(harness.adapter.chrome[row].decorations)")
        }
        let live = heights(harness)
        harness.adapter.reloadAll()
        try await harness.settle(150)
        let fresh = heights(harness)
        #expect(live.count == fresh.count, "live \(live), fresh \(fresh)")
        for (index, pair) in zip(live, fresh).enumerated() {
            #expect(abs(pair.0 - pair.1) < 0.5, "item \(index): live \(pair.0), fresh \(pair.1). live \(live), fresh \(fresh)")
        }
    }
}
