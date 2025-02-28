import MEGADesignToken
import SwiftUI

public class HorizontalTagListViewModel: ObservableObject {
    @Published public private(set) var tags: [AttributedString]

    public init(tags: [AttributedString]) {
        self.tags = tags
    }

    public func updateTags(_ tags: [AttributedString]) {
        self.tags = tags
    }
}

public struct HorizontalTagListView: View {
    @StateObject private var viewModel: HorizontalTagListViewModel

    public init(viewModel: @autoclosure @escaping () -> HorizontalTagListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: TokenSpacing._3) {
                ForEach(viewModel.tags, id: \.self) { tag in
                    Text(tag)
                        .tagStyle(backgroundColor: TokenColors.Button.secondary.swiftUI)
                }
            }
        }
    }
}
