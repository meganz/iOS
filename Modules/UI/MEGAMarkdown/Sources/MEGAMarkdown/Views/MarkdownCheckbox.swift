import MEGADesignToken
import SwiftUI

/// Task list checkbox. `package`, so other targets of this package draw the same box.
/// Colors come from the theme. The tick is a path, so it needs no image resource.
package struct MarkdownCheckbox: View {
    let isChecked: Bool
    @Environment(\.markdownTheme) private var theme
    @ScaledMetric(relativeTo: .body) private var size = TokenSpacing._6

    package init(isChecked: Bool) {
        self.isChecked = isChecked
    }

    package var body: some View {
        let shape = RoundedRectangle(cornerRadius: TokenRadius.extraSmall)
        ZStack {
            if isChecked {
                shape.fill(theme.checkboxCheckedColor)
                MarkdownCheckmark()
                    .stroke(theme.checkboxTickColor, style: StrokeStyle(lineWidth: size * Self.tickWidthRatio, lineCap: .round, lineJoin: .round))
                    .padding(size * Self.tickInsetRatio)
            } else {
                shape.fill(theme.checkboxUncheckedColor)
                shape.strokeBorder(theme.checkboxBorderColor, lineWidth: Self.borderWidth)
            }
        }
        .frame(width: size, height: size)
        // A checkmark is never mirrored. Without this, a right-to-left row in a left-to-right app showed a "v" on screen.
        .environment(\.layoutDirection, .leftToRight)
    }

    // No design token for border width or drawing ratios. Internal, so other views can use them.
    /// The tick is 1.5 wide in a 20 pt box. The ratios make it scale with the box.
    static let tickWidthRatio: CGFloat = 1.5 / 20
    static let tickInsetRatio: CGFloat = 0.1
    static let borderWidth: CGFloat = 1
}

/// The Figma tick: the centre line of a 1.5 wide stroke in a 16 x 16 box.
struct MarkdownCheckmark: Shape {
    func path(in rect: CGRect) -> Path {
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + rect.width * x / 16, y: rect.minY + rect.height * y / 16)
        }
        var path = Path()
        path.move(to: point(3.5, 9))
        path.addLine(to: point(6, 11.5))
        path.addLine(to: point(12.5, 5))
        return path
    }
}
