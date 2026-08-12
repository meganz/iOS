import MEGAAppPresentation
import MEGADesignToken
import MEGADomain
import SwiftUI

/// The file link screen once the link has resolved: the preview area above the file's name and
/// details.
struct FileLinkContentView: View {
    private enum Constants {
        static let nameLineLimit = 3
    }

    @StateObject private var viewModel: FileLinkContentViewModel

    init(node: NodeEntity, previewLoader: some ThumbnailLoaderProtocol) {
        _viewModel = StateObject(
            wrappedValue: FileLinkContentViewModel(node: node, thumbnailLoader: previewLoader)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FileLinkPreviewView(preview: viewModel.preview)

            // Pinned to the height its text needs, so that when the screen is too short for both --
            // landscape, or large accessibility text -- the preview area above gives up the space
            // instead of the name being truncated.
            details
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(TokenColors.Background.page.swiftUI)
        .task {
            await viewModel.loadPreview()
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._1) {
            Text(viewModel.name)
                .font(.body)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                .lineLimit(Constants.nameLineLimit)

            Text(viewModel.details)
                .font(.footnote)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, TokenSpacing._4)
        .padding(.trailing, TokenSpacing._5)
        .padding(.vertical, TokenSpacing._3)
    }
}
