import Foundation
@testable import MEGAMarkdownEditor
import SwiftUI
import Testing
import UIKit

// Needs the iOS simulator: the saver waits in a SwiftUI task.
@MainActor
@Suite(.serialized, .hostedUI, .timeLimit(.minutes(1)))
struct RichIdleSaverTests {
    private final class Writes {
        var values: [String] = []
    }

    /// Short, so the tests stay fast. The key gaps below are chosen against it.
    private static let delay = Duration.milliseconds(1_000)

    private func host(_ model: RichEditorModel) -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 200))
        window.rootViewController = UIHostingController(rootView: RichIdleSaver(model: model, delay: Self.delay))
        window.isHidden = false
        return window
    }

    private func makeModel(_ markdown: String, writes: Writes) -> RichEditorModel {
        let model = RichEditorModel(editor: RichEditor(markdown: markdown))
        model.onExport = { writes.values.append($0) }
        return model
    }

    @Test func savesOnceAfterTheDelayFromTheLastKey() async throws {
        let writes = Writes()
        let model = makeModel("a", writes: writes)
        let window = host(model)
        defer { window.isHidden = true }
        for offset in 1...3 {
            model.replaceText(inRow: 0, range: offset..<offset, with: "b")
            try await Task.sleep(for: .milliseconds(100))
        }
        // 300 ms after the first key, but only 100 ms after the last one.
        #expect(writes.values.isEmpty)
        try await waitUntil("the idle save") { !writes.values.isEmpty }
        #expect(writes.values.map { $0.trimmingCharacters(in: .newlines) } == ["abbb"])
        // A second save would come one delay later. Wait two delays.
        try await Task.sleep(for: Self.delay * 2)
        #expect(writes.values.count == 1)
    }

    /// The pause ends the typing burst, so keys after it are a new undo step.
    @Test func pauseStartsANewUndoStep() async throws {
        let writes = Writes()
        let model = makeModel("a", writes: writes)
        let window = host(model)
        defer { window.isHidden = true }
        model.replaceText(inRow: 0, range: 1..<1, with: "b")
        try await waitUntil("the idle save") { !writes.values.isEmpty }
        model.replaceText(inRow: 0, range: 2..<2, with: "c")
        model.undo()
        #expect(model.row(at: 0).block == paragraph("ab"))
    }

    /// Marked text of an input method is not final. The save waits until it is committed.
    @Test func waitsWhileTextIsMarked() async throws {
        let writes = Writes()
        let model = makeModel("a", writes: writes)
        var isMarked = true
        model.hasMarkedText = { isMarked }
        let window = host(model)
        defer { window.isHidden = true }
        model.replaceText(inRow: 0, range: 1..<1, with: "n")
        try await Task.sleep(for: Self.delay * 2)
        #expect(writes.values.isEmpty)
        isMarked = false
        try await waitUntil("the idle save") { !writes.values.isEmpty }
        #expect(writes.values.map { $0.trimmingCharacters(in: .newlines) } == ["an"])
    }

    @Test func openingWithoutAnEditWritesNothing() async throws {
        let writes = Writes()
        let model = makeModel("# Title\r\n\r\nSome *text*\r\n", writes: writes)
        let window = host(model)
        defer { window.isHidden = true }
        // No edit means no task to wait for. Wait past one delay.
        try await Task.sleep(for: Self.delay * 2)
        #expect(writes.values.isEmpty)
    }
}
