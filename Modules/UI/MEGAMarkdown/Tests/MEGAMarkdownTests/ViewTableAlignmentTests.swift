@testable import MEGAMarkdown
import SwiftUI
import Testing
import UIKit

/// An explicit column alignment is a physical side, like `align="left"` in cmark's HTML.
/// It must not flip in a right-to-left layout. Uses a real window, because ImageRenderer draws no ScrollView content.
@MainActor
@Suite struct ViewTableAlignmentTests {
    struct Case: CustomTestStringConvertible, Sendable {
        let alignment: MarkdownTable.Alignment
        let direction: LayoutDirection
        let textIsOnTheLeft: Bool

        var testDescription: String { "\(alignment) in \(direction)" }
    }

    nonisolated static let cases = [
        Case(alignment: .left, direction: .leftToRight, textIsOnTheLeft: true),
        Case(alignment: .right, direction: .leftToRight, textIsOnTheLeft: false),
        Case(alignment: .left, direction: .rightToLeft, textIsOnTheLeft: true),
        Case(alignment: .right, direction: .rightToLeft, textIsOnTheLeft: false)
    ]

    /// Pixel rows of a rendered window, 4 bytes (RGBA) per pixel.
    private struct Pixels {
        let width: Int
        let height: Int
        let bytes: [UInt8]

        func columns(where isMatch: (UInt8, UInt8, UInt8) -> Bool) -> ClosedRange<Int>? {
            var minX = Int.max, maxX = Int.min
            for y in 0..<height {
                for x in 0..<width {
                    let index = (y * width + x) * 4
                    if isMatch(bytes[index], bytes[index + 1], bytes[index + 2]) {
                        minX = min(minX, x)
                        maxX = max(maxX, x)
                    }
                }
            }
            return minX <= maxX ? minX...maxX : nil
        }
    }

    private func render(_ table: MarkdownTable, direction: LayoutDirection) throws -> Pixels {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 200))
        window.overrideUserInterfaceStyle = .light
        var theme = MarkdownTheme.default
        // A pure red border is easy to find among the pixels.
        theme.tableBorderColor = Color(red: 1, green: 0, blue: 0)
        let root = TableBlockView(table: table, showsHeader: false)
            .markdownTheme(theme)
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.white)
            .environment(\.layoutDirection, direction)
        let host = UIHostingController(rootView: root)
        window.rootViewController = host
        window.isHidden = false
        window.layoutIfNeeded()
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        // The test window has no screen, so `drawHierarchy` draws nothing. The layer tree is still there.
        let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { context in
            host.view.layer.render(in: context.cgContext)
        }
        let cgImage = try #require(image.cgImage)
        let width = cgImage.width, height = cgImage.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = bytes.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        try #require(drawn)
        return Pixels(width: width, height: height, bytes: bytes)
    }

    @Test(arguments: cases)
    func explicitAlignmentKeepsItsSide(_ testCase: Case) throws {
        let table = MarkdownTable(columns: [.init(alignment: testCase.alignment)], header: [""], rows: [["MM"]])
        let pixels = try render(table, direction: testCase.direction)
        // The table border is red and the text is near black, on a white page.
        let tableColumns = try #require(pixels.columns { $0 > 200 && $1 < 80 && $2 < 80 }, "no table drawn")
        let textColumns = try #require(pixels.columns { $0 < 100 && $1 < 100 && $2 < 100 }, "no text drawn")
        let tableMiddle = (tableColumns.lowerBound + tableColumns.upperBound) / 2
        let textMiddle = (textColumns.lowerBound + textColumns.upperBound) / 2
        #expect((textMiddle < tableMiddle) == testCase.textIsOnTheLeft, "table \(tableColumns), text \(textColumns)")
    }
}
