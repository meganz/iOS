import MEGADesignToken
import MEGASwift
import SwiftUI

struct NodeTagsView: View {
    // MARK: - LayoutState
    /// A private class for managing layout state during the arrangement of tags.
    ///
    /// This class ensures thread-safe access to its properties using a
    /// `@Atomic` property wrapper. It tracks the current position (`currentOffset`).
    /// and the maximum height of the current row (`maxRowHeight`).
    private final class LayoutState: @unchecked Sendable {
        @Atomic var currentOffset: CGPoint = .zero
        @Atomic var maxRowHeight: CGFloat = 0

        func set(maxRowHeight: CGFloat) {
            $maxRowHeight.mutate {  $0 = maxRowHeight }
        }

        func set(x: CGFloat? = nil, y: CGFloat? = nil) {
            guard x != nil || y != nil else { return }
            let updatedValue = CGPoint(x: x ?? currentOffset.x, y: y ?? currentOffset.y)
            $currentOffset.mutate { $0 = updatedValue }
        }
    }

    // MARK: - Properties
    @ObservedObject private var viewModel: NodeTagsViewModel
    private let padding: CGFloat = TokenSpacing._3

    init(viewModel: NodeTagsViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            arrangeContent(in: geometry)
        }
        .frame(height: viewModel.viewHeight)
    }

    // MARK: - Helper Methods
    @ViewBuilder
    private func arrangeContent(in geometry: GeometryProxy) -> some View {
        ZStack {
            let tagViewModels = viewModel.tagViewModels
            let layoutState = LayoutState()
            let containerWidth = geometry.size.width

            ForEach(tagViewModels.indices, id: \.self) { index in
                let tagViewModel = tagViewModels[index]
                let isLastElement = index == tagViewModels.count - 1
                createNodeTagView(
                    for: tagViewModel,
                    layoutState: layoutState,
                    containerWidth: containerWidth,
                    isLastElement: isLastElement
                )
            }
        }
        .background(updateHeight())
    }

    @ViewBuilder
    private func createNodeTagView(
        for tagViewModel: NodeTagViewModel,
        layoutState: LayoutState,
        containerWidth: CGFloat,
        isLastElement: Bool
    ) -> some View {
        nodeTagView(for: tagViewModel)
            .allowsHitTesting(viewModel.isSelectionEnabled)
            .onTapGesture {
                tagViewModel.toggle()
            }
            .alignmentGuide(HorizontalAlignment.center) { dimension in
                calculateHorizontalAlignment(
                    dimension: dimension,
                    layoutState: layoutState,
                    containerWidth: containerWidth,
                    isLastElement: isLastElement
                )
            }
            .alignmentGuide(VerticalAlignment.center) { _ in
                calculateVerticalAlignment(layoutState: layoutState, isLastElement: isLastElement)
            }
    }

    nonisolated private func calculateHorizontalAlignment(
        dimension: ViewDimensions,
        layoutState: LayoutState,
        containerWidth: CGFloat,
        isLastElement: Bool
    ) -> CGFloat {
        // Check if placing the current element exceeds the container's width
        if (layoutState.currentOffset.x + dimension.width) > containerWidth {
            // Move to the next row:
            // - Reset horizontal (x) offset to 0
            // - Increase vertical (y) offset by the max height of the current row plus padding
            layoutState.set(x: 0, y: (layoutState.currentOffset.y + layoutState.maxRowHeight + padding))
            // Reset the maximum row height since we are starting a new row
            layoutState.set(maxRowHeight: 0)
        }

        // Update the maximum row height to ensure enough vertical space for the row
        layoutState.set(maxRowHeight: max(layoutState.maxRowHeight, dimension.height))

        let offsetX = layoutState.currentOffset.x
        // Update the horizontal (x) offset for the next element by adding the current element's width and padding
        layoutState.set(x: (offsetX + dimension.width + padding))

        // If this is the last element, reset layout state to initial values
        if isLastElement {
            layoutState.set(x: 0)
            layoutState.set(maxRowHeight: 0)
        }

        return -offsetX
    }

    nonisolated private func calculateVerticalAlignment(layoutState: LayoutState, isLastElement: Bool) -> CGFloat {
        let offsetY = layoutState.currentOffset.y

        // If this is the last element, reset layout state to initial values
        if isLastElement {
            // Reset y-offset while keeping the current x-offset
            layoutState.set(x: layoutState.currentOffset.x, y: 0)
        }

        return -offsetY
    }

    @ViewBuilder
    private func nodeTagView(for tagViewModel: NodeTagViewModel) -> some View {
        if tagViewModel.isSelected {
            NodeTagSelectedView(tag: tagViewModel.formattedTag)
        } else {
            NodeTagNormalView(tag: tagViewModel.formattedTag)
        }
    }

    private func updateHeight() -> some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear {
                    viewModel.viewHeight = proxy.size.height
                }
                .onChange(of: proxy.size.height) { newValue in
                    viewModel.viewHeight = newValue
                }
        }
    }
}
