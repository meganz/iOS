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
        .background(backgroundColor)
    }

    private func view(for text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(TokenColors.Text.secondary.swiftUI)
    }

    private var backgroundColor: Color {
        isDesignTokenEnabled
        ? TokenColors.Background.page.swiftUI
        : colorScheme == .dark
        ? Color(UIColor.black1C1C1E)
        : Color(UIColor.whiteF7F7F7)
    }
}
