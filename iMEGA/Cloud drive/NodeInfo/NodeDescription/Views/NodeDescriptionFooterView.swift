import MEGADesignToken
import SwiftUI

struct NodeDescriptionFooterView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject var viewModel: NodeDescriptionFooterViewModel

    var body: some View {
        VStack(spacing: 0) {
            NodeDescriptionSeparatorView()
            textView
        }
    }

    private var textView: some View {
        HStack {
            view(for: viewModel.leadingText ?? "")
            Spacer()
            view(for: viewModel.trailingText ?? "")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background()
    }

    private func view(for text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(TokenColors.Text.secondary.swiftUI)
    }
}
