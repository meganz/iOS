import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct NodeTagsView: View {
    @ObservedObject var viewModel: NodeTagsViewModel
    private let padding: CGFloat = TokenSpacing._3

    var body: some View {
        ZStack(alignment: .leading) {
            hiddenTagsWidthTrackerView
            widthTrackerView
            visibleTagsGridView
        }
    }

    // Displays the tags in a grid-like structure
    private var visibleTagsGridView: some View {
        VStack(alignment: .leading, spacing: padding) {
            ForEach(tagGrid, id: \.self) { rows in
                HStack(spacing: padding) {
                    ForEach(rows, id: \.self) { tag in
                        pillView(for: tag)
                    }
                }
            }
        }
    }

    // Tracks the total width of the view
    private var widthTrackerView: some View {
        Color.clear
            .trackWidth()
            .onPreferenceChange(WidthPreferenceKey.self) { newValue in
                viewModel.viewWidth = newValue
            }
    }

    // Tracks the width of each individual tag
    private var hiddenTagsWidthTrackerView: some View {
        ForEach(tagGrid, id: \.self) { rows in
            ForEach(rows, id: \.self) { tag in
                pillView(for: tag)
                    .opacity(0)  // invisible, for measurement only
                    .trackWidth()
                    .onPreferenceChange(WidthPreferenceKey.self) { width in
                        viewModel.update(tag, with: width)
                    }
            }
        }
    }

    private func pillView(for tag: String) -> some View {
        PillView(
            viewModel: PillViewModel(
                title: tag,
                icon: .none,
                foreground: TokenColors.Text.primary.swiftUI,
                background: TokenColors.Button.secondary.swiftUI,
                font: .subheadline
            )
        )
    }

    // Calculate how to arrange tags into rows based on the available width
    private var tagGrid: [[String]] {
        var grid: [[String]] = [[]]
        var remainingWidth = viewModel.viewWidth

        for tag in viewModel.tags {
            let tagWidth = viewModel.tagsWidth[tag] ?? viewModel.viewWidth

            // Check if the tag can fit in the current row
            if remainingWidth <= tagWidth {
                // Move to the next row if the current row can't fit the tag
                grid.append([])
                // Reset remaining width for the new row
                remainingWidth = viewModel.viewWidth
            }

            // Add the tag to the current row
            grid[grid.count - 1].append(tag)
            // Update remaining width after adding the tag
            remainingWidth -= (tagWidth + padding)
        }
        
        return grid
    }
}

private extension View {
    func trackWidth() -> some View {
        modifier(WidthModifier())
    }
}

private struct WidthModifier: ViewModifier {
    private var widthView: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(key: WidthPreferenceKey.self, value: proxy.size.width)
        }
    }

    func body(content: Content) -> some View {
        content.background(widthView)
    }
}

private struct WidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
