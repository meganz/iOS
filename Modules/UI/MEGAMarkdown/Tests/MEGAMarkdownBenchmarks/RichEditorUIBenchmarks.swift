import MEGABenchmark
@testable import MEGAMarkdownEditor
import QuartzCore
import SwiftUI
import UIKit
import XCTest

/// The editor in a window: keys and Enter at the rich limit, opening rich and source mode.
/// They run only with `TEST_RUNNER_MEGA_BENCH=1`.
@MainActor
final class RichEditorUIBenchmarks: BenchmarkCase {
    private static let phoneSize = CGSize(width: 402, height: 874)
    /// 166,666 rows of 1 character: a file at the rich limit (500,000 UTF-16 units) with the most rows.
    private static let manyRows = String(repeating: "a\n\n", count: 166_666)

    private struct LoadFailed: Error, CustomStringConvertible {
        var description: String { "The benchmark document did not load as a rich document" }
    }

    @MainActor
    private struct Session {
        let window: UIWindow
        let adapter: RichRowAdapter

        func close() {
            window.endEditing(true)
            window.rootViewController = nil
            window.isHidden = true
        }

        var focusedTextView: RichTextView? {
            var pending: [UIView] = [window]
            while let view = pending.popLast() {
                if let textView = view as? RichTextView, textView.isFirstResponder { return textView }
                pending.append(contentsOf: view.subviews)
            }
            return nil
        }
    }

    /// Rich mode in a window. The load runs here on the main thread, before any measure.
    private func open(_ markdown: String) throws -> Session {
        guard case .loaded(let load) = RichEditorLoad.make(markdown) else { throw LoadFailed() }
        let adapter = RichRowAdapter(model: RichEditorModel(editor: load.editor), load: load)
        return host(adapter)
    }

    private func host(_ adapter: RichRowAdapter) -> Session {
        let window = UIWindow(frame: CGRect(origin: .zero, size: Self.phoneSize))
        window.rootViewController = UIHostingController(rootView: RichEditorView(adapter: adapter, baseURL: nil))
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        CATransaction.flush()
        return Session(window: window, adapter: adapter)
    }

    /// Puts the caret in `row`, through the focus path.
    private func focus(_ session: Session, row: Int) throws -> RichTextView {
        let model = session.adapter.model
        model.setFocused(true)
        model.select(.caret(RichPosition(blockIndex: row, offset: model.row(at: row).block.length)))
        return try XCTUnwrap(session.focusedTextView)
    }

    private func type(_ text: String, into textView: RichTextView) {
        let range = textView.selectedRange
        if textView.delegate?.textView?(textView, shouldChangeTextIn: range, replacementText: text) ?? true {
            textView.insertText(text)
        }
    }

    // MARK: - Keys

    /// 50 keys in a row in the middle of 166,666 rows. Divide by 50 for one key.
    func testKeysAt167kRows() throws {
        let session = try open(Self.manyRows)
        defer { session.close() }
        let textView = try focus(session, row: 83_333)
        let model = session.adapter.model
        let original = model.row(at: 83_333).block
        let options = XCTMeasureOptions.default
        options.invocationOptions = [.manuallyStop]
        measure(metrics: [XCTClockMetric(), XCTCPUMetric()], options: options) {
            for _ in 0..<50 { type("b", into: textView) }
            stopMeasuring()
            // One undo step per typing burst. Every run then starts from the opened document.
            model.undo()
        }
        XCTAssertEqual(model.row(at: 83_333).block, original)
        XCTAssertEqual(session.adapter.appliedVersion, model.version)
    }

    /// 10 Enters in the middle of 166,666 rows: each one inserts an item and moves the focus. Divide by 10.
    func testEnterAt167kRows() throws {
        let session = try open(Self.manyRows)
        defer { session.close() }
        _ = try focus(session, row: 83_333)
        let model = session.adapter.model
        let rowCount = model.rowCount
        let options = XCTMeasureOptions.default
        options.invocationOptions = [.manuallyStop]
        measure(metrics: [XCTClockMetric(), XCTCPUMetric()], options: options) {
            for _ in 0..<10 {
                // No early return: stopMeasuring and the undo below must still run.
                guard let textView = session.focusedTextView else {
                    XCTFail("no focused row")
                    break
                }
                type("\n", into: textView)
            }
            stopMeasuring()
            // Every run then starts from the opened document.
            for _ in 0..<10 { model.undo() }
        }
        XCTAssertEqual(model.rowCount, rowCount)
        XCTAssertEqual(session.adapter.list.itemCount, model.rowCount)
    }

    // MARK: - Open

    /// The main thread part of opening rich mode at the limit: the adapter and the first frame of the list.
    /// The load before it runs off the main thread in the editor.
    func testOpenRichModeAtLimitMainThread() throws {
        guard case .loaded(let load) = RichEditorLoad.make(Self.manyRows) else { throw LoadFailed() }
        let options = XCTMeasureOptions.default
        options.invocationOptions = [.manuallyStop]
        measure(metrics: [XCTClockMetric(), MainThreadStallMetric(), PeakFootprintMetric()], options: options) {
            let session = host(RichRowAdapter(model: RichEditorModel(editor: load.editor), load: load))
            stopMeasuring()
            XCTAssertGreaterThan(session.adapter.list.view.indexPathsForVisibleItems.count, 0)
            session.close()
        }
    }

    func testOpenSourceModeTwoMegabytes() throws {
        try measureSourceOpen(BenchmarkDocuments.makeLargeDocument(targetBytes: 2_000_000))
    }

    func testOpenSourceModeTenMegabytes() throws {
        try measureSourceOpen(BenchmarkDocuments.makeLargeDocument(targetBytes: 10_000_000))
    }

    /// From hosting the editor to the source text view on screen. The limit check runs off the main thread in between.
    private func measureSourceOpen(_ markdown: String) throws {
        let options = XCTMeasureOptions.default
        options.invocationOptions = [.manuallyStop]
        measure(metrics: [XCTClockMetric(), MainThreadStallMetric(), PeakFootprintMetric()], options: options) {
            let window = UIWindow(frame: CGRect(origin: .zero, size: Self.phoneSize))
            window.rootViewController = UIHostingController(rootView: SourceHost(markdown: markdown))
            window.makeKeyAndVisible()
            let deadline = Date().addingTimeInterval(30)
            while Self.sourceTextView(in: window) == nil, Date() < deadline {
                RunLoop.main.run(until: Date().addingTimeInterval(0.005))
            }
            window.layoutIfNeeded()
            CATransaction.flush()
            stopMeasuring()
            XCTAssertNotNil(Self.sourceTextView(in: window), "The source text view did not appear in 30 s, so this sample is not valid")
            window.rootViewController = nil
            window.isHidden = true
        }
    }

    private static func sourceTextView(in view: UIView) -> UITextView? {
        if let textView = view as? UITextView, textView.accessibilityIdentifier == "editor.source" { return textView }
        return view.subviews.lazy.compactMap { sourceTextView(in: $0) }.first
    }

    private struct SourceHost: View {
        @State var markdown: String
        @State private var mode = MarkdownEditorMode.source

        var body: some View {
            MarkdownEditor(markdown: $markdown, mode: $mode)
        }
    }
}
