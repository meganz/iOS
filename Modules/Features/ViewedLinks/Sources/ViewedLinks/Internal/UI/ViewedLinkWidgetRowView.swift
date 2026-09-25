import MEGADesignToken
import SwiftUI

struct ViewedLinkWidgetRowView: View {
    @StateObject private var viewModel: ViewedLinkWidgetRowViewModel
    private let onTap: @MainActor () -> Void

    init(
        link: ViewedLinkWidgetRowModel,
        onTap: @escaping @MainActor () -> Void
    ) {
        self.onTap = onTap
        _viewModel = StateObject(
            wrappedValue: ViewedLinkWidgetRowViewModel(link: link)
        )
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: TokenSpacing._3) {
                viewModel.imageContainer
                    .image
                    .resizable()
                    .aspectRatio(contentMode: viewModel.hasThumbnail ? .fill : .fit)
                    .frame(width: TokenSpacing._9, height: TokenSpacing._9)
                    .clipShape(RoundedRectangle(cornerRadius: TokenRadius.small))

                Text(viewModel.name)
                    .font(.subheadline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, TokenSpacing._5)
            .padding(.vertical, TokenSpacing._3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .task {
            await viewModel.loadThumbnail()
        }

    }
}
