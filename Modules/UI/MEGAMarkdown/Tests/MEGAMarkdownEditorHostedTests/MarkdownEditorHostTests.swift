import Foundation
import MEGAMarkdown
@testable import MEGAMarkdownEditor
import Observation
import SwiftUI
import Testing
import UIKit

// Needs the iOS simulator. A host changes what it passes to the editor while the editor is on screen.
@MainActor
@Suite(.serialized, .hostedUI, .timeLimit(.minutes(2)))
struct MarkdownEditorHostTests {
    // MARK: - Binding

    @MainActor
    @Observable
    final class TwoDocuments {
        var first: String
        var second: String
        var showsSecond = false
        var mode = MarkdownEditorMode.rich
        /// Counts the host renders that used the second note.
        @ObservationIgnored var secondRenders = 0

        init(_ text: String) {
            first = text
            second = text
        }
    }

    private struct TwoDocumentsHost: View {
        @Bindable var documents: TwoDocuments

        var body: some View {
            let _ = noteRender()
            MarkdownEditor(markdown: documents.showsSecond ? $documents.second : $documents.first, mode: $documents.mode)
        }

        private func noteRender() {
            if documents.showsSecond { documents.secondRenders += 1 }
        }
    }

    /// Two notes with equal text can use one editor view. Keys in the second note must reach the second binding.
    @Test(arguments: ["abc", ""])
    func exportGoesToTheBindingOfTheLatestRender(_ start: String) async throws {
        let documents = TwoDocuments(start)
        let window = Self.show(TwoDocumentsHost(documents: documents))
        defer { Self.close(window) }
        let textView = try await Self.waitForRichRow(in: window)
        documents.showsSecond = true
        // One render pass runs the host and the editor on the main actor, so the editor has the new binding when this wait ends.
        try await waitUntil("a render with the second note") { documents.secondRenders > 0 }
        textView.becomeFirstResponder()
        textView.selectedRange = NSRange(location: (textView.text as NSString).length, length: 0)
        if textView.delegate?.textView?(textView, shouldChangeTextIn: textView.selectedRange, replacementText: "x") ?? true {
            textView.insertText("x")
        }
        NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil)
        #expect(documents.first == start)
        #expect(documents.second.trimmingCharacters(in: .newlines) == start + "x")
    }

    /// After a save, the loaded text is no longer the editor's text. The host can set it back, and the editor shows it.
    @Test func outsideRevertToTheLoadedTextReloads() async throws {
        let host = EditorWindow("abc", mode: .rich)
        defer { host.close() }
        let row = try await host.waitForRichRow("abc")
        host.typeAtEnd("x", into: row)
        NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil)
        try await waitUntil("the background save") { host.model.text.trimmingCharacters(in: .newlines) == "abcx" }
        // The editor must see "abcx" first. Else the revert to "abc" looks like no change.
        try await EditorWindow.settle()
        host.model.text = "abc"
        try await waitUntil("the reloaded row") { host.richTextViews.first?.text == "abc" }
    }

    // MARK: - Images

    private final class URLLog: @unchecked Sendable {
        private let lock = NSLock()
        private var urls: [URL] = []
        var paths: [String] { lock.withLock { urls.map(\.path) } }
        func record(_ url: URL) { lock.withLock { urls.append(url) } }
    }

    @MainActor
    @Observable
    final class ImageSettings {
        var text = "![picture](picture.png)\n"
        var mode = MarkdownEditorMode.rich
        var provides: Bool
        var baseURL = URL(fileURLWithPath: "/first/")

        init(provides: Bool) { self.provides = provides }
    }

    private struct ImageHost: View {
        @Bindable var settings: ImageSettings
        let log: URLLog

        var body: some View {
            MarkdownEditor(markdown: $settings.text, mode: $settings.mode, baseURL: settings.baseURL)
                .environment(\.markdownImageLoading, settings.provides ? .provided { url in
                    log.record(url)
                    return nil
                } : .altTextOnly)
        }
    }

    @Test func imageProviderSetLaterReachesAVisibleImage() async throws {
        let log = URLLog()
        let settings = ImageSettings(provides: false)
        let window = Self.show(ImageHost(settings: settings, log: log))
        defer { Self.close(window) }
        // The rows are a collection view. It has a cell once the rich load has finished.
        try await waitUntil("a row of the rich list") { Self.hasCell(in: window) }
        settings.provides = true
        try await waitUntil("a load of /first/picture.png") { log.paths.contains("/first/picture.png") }
    }

    @Test func newBaseURLReachesAVisibleImage() async throws {
        let log = URLLog()
        let settings = ImageSettings(provides: true)
        let window = Self.show(ImageHost(settings: settings, log: log))
        defer { Self.close(window) }
        try await waitUntil("a load of /first/picture.png") { log.paths.contains("/first/picture.png") }
        settings.baseURL = URL(fileURLWithPath: "/second/")
        try await waitUntil("a load of /second/picture.png") { log.paths.contains("/second/picture.png") }
    }

    // MARK: - Helpers

    private static func show(_ view: some View) -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 700))
        window.rootViewController = UIHostingController(rootView: view)
        window.makeKeyAndVisible()
        return window
    }

    private static func close(_ window: UIWindow) {
        window.endEditing(true)
        window.isHidden = true
        window.rootViewController = nil
    }

    private static func waitForRichRow(in window: UIWindow) async throws -> RichTextView {
        try await waitForValue("a rich row") { firstRow(in: window) }
    }

    private static func hasCell(in view: UIView) -> Bool {
        if let collection = view as? UICollectionView, !collection.visibleCells.isEmpty { return true }
        return view.subviews.contains { hasCell(in: $0) }
    }

    private static func firstRow(in view: UIView) -> RichTextView? {
        if let row = view as? RichTextView, !row.isHidden { return row }
        return view.subviews.lazy.compactMap { firstRow(in: $0) }.first
    }
}
