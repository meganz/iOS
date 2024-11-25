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
            ForEach(0..<tagGrid.count, id: \.self) { rowIndex in
                let tagViewModels = tagGrid[rowIndex]
                HStack(spacing: padding) {
                    ForEach(tagViewModels, id: \.tag) { tagViewModel in
                        nodeTagView(for: tagViewModel)
                            .allowsHitTesting(tagViewModel.isSelectionEnabled)
                            .onTapGesture {
                                tagViewModel.toggle()
                            }
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
        ForEach(0..<tagGrid.count, id: \.self) { rowIndex in
            let tagViewModels = tagGrid[rowIndex]
            ForEach(tagViewModels, id: \.tag) { tagViewModel in
                nodeTagView(for: tagViewModel)
                    .opacity(0)  // invisible, for measurement only
                    .trackWidth()
                    .onPreferenceChange(WidthPreferenceKey.self) { width in
                        viewModel.update(tagViewModel.tag, with: width)
                    }
            }
        }
    }

    @ViewBuilder
    private func nodeTagView(for tagViewModel: NodeTagViewModel) -> some View {
        if tagViewModel.isSelected {
            NodeTagSelectedView(tag: tagViewModel.formattedTag)
        } else {
            NodeTagNormalView(tag: tagViewModel.formattedTag)
        }
    }

    // Calculate how to arrange tags into rows based on the available width
    private var tagGrid: [[NodeTagViewModel]] {
        var grid: [[NodeTagViewModel]] = [[]]
        var remainingWidth = viewModel.viewWidth

        for tagViewModel in viewModel.tagViewModels {
            let tagWidth = viewModel.tagsWidth[tagViewModel.tag] ?? viewModel.viewWidth

            // Check if the tag can fit in the current row
            if remainingWidth <= tagWidth {
                // Move to the next row if the current row can't fit the tag
                grid.append([])
                // Reset remaining width for the new row
                remainingWidth = viewModel.viewWidth
            }

            // Add the tag to the current row
            grid[grid.count - 1].append(tagViewModel)
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

actor WidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
