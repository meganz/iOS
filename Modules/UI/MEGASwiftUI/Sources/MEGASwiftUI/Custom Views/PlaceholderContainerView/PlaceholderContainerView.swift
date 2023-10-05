import SwiftUI

public struct PlaceholderContainerView<Content: View, WrappedView: View>: View {
    @Binding var isLoading: Bool
    let contentView: Content
    let placeholderView: PlaceholderContentView<WrappedView>

    public init(
        isLoading: Binding<Bool>,
        content: Content,
        placeholder: PlaceholderContentView<WrappedView>
    ) {
        self._isLoading = isLoading
        self.contentView = content
        self.placeholderView = placeholder
    }

    public var body: some View {
        Group {
            if isLoading {
                placeholderView
            } else {
                contentView
            }
        }
    }
}

public struct PlaceholderContentView<WrappedView: View>: View {
    let placeholderRow: WrappedView
    let itemCount: Int
    
    public init(placeholderRow: WrappedView, itemCount: Int = 9) {
        self.placeholderRow = placeholderRow
        self.itemCount = itemCount
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: .zero) {
                ForEach(0..<itemCount, id: \.self) { _ in
                    placeholderRow
                }
            }
        }
    }
}
