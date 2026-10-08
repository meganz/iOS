import CoreGraphics
@testable import MEGAMarkdownEditor
import Testing
import UIKit

// Needs the iOS simulator: the asset catalog must be compiled for the images to load.
@MainActor
@Suite struct MarkdownEditorIconTests {
    @Test(arguments: MarkdownEditorIcon.allCases)
    func iconLoadsAsTemplate(icon: MarkdownEditorIcon) throws {
        let image = try #require(icon.uiImage, "\(icon.rawValue) did not load")
        #expect(image.renderingMode == .alwaysTemplate)
        let side: CGFloat = icon == .chevronDown ? 16 : 24
        #expect(image.size == CGSize(width: side, height: side))
    }
}
