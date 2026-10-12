@testable import MEGATextEditor
import SwiftUI
import Testing
import UIKit

@MainActor
struct MarkdownTextEditorContentViewLifetimeTests {
    @Test(arguments: [MarkdownTextEditorContentState.Screen.preview, .editor])
    func stateIsFreedAfterTheScreenCloses(screen: MarkdownTextEditorContentState.Screen) async throws {
        weak var weakState: MarkdownTextEditorContentState?
        do {
            let state = MarkdownTextEditorContentState()
            state.text = "# Hello"
            state.screen = screen
            weakState = state
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
            window.rootViewController = UIHostingController(rootView: MarkdownTextEditorContentView(state: state))
            window.makeKeyAndVisible()
            window.layoutIfNeeded()
            // The editor connects the flusher of the state only after it appears in a window.
            try await Task.sleep(for: .milliseconds(500))
            window.rootViewController = nil
            window.isHidden = true
        }

        for _ in 0..<100 where weakState != nil {
            try await Task.sleep(for: .milliseconds(10))
        }

        #expect(weakState == nil)
    }
}
