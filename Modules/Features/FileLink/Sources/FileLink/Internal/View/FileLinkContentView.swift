import MEGAAppPresentation
import MEGADesignToken
import MEGADomain
import MEGAL10n
import SwiftUI

/// The file link screen once the link has resolved: the preview area above the file's name and
/// details, either of which opens the file.
struct FileLinkContentView: View {
    private enum Constants {
        static let nameLineLimit = 3
        /// The padding the design draws around `Open`, which does not sit on the spacing token scale.
        static let openButtonHorizontalPadding: CGFloat = 14
        static let openButtonVerticalPadding: CGFloat = 7
    }

    @StateObject private var viewModel: FileLinkContentViewModel

    init(
        node: NodeEntity,
        previewLoader: some ThumbnailLoaderProtocol,
        fileNodeOpener: some FileLinkNodeOpenerProtocol
    ) {
        _viewModel = StateObject(
            wrappedValue: FileLinkContentViewModel(
                node: node,
                thumbnailLoader: previewLoader,
                fileNodeOpener: fileNodeOpener
            )
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            previewButton

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

    /// The whole preview area opens the file, the play button drawn on a video included: nothing plays
    /// in place. `Open` below does the same thing and is the one VoiceOver reads, so this is kept out
    /// of its way rather than offering the same action twice.
    private var previewButton: some View {
        Button(action: openFile) {
            FileLinkPreviewView(preview: viewModel.preview)
        }
        .buttonStyle(.plain)
        .accessibilityHidden(true)
    }

    private var details: some View {
        HStack(spacing: TokenSpacing._4) {
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

            openButton
        }
        .padding(.leading, TokenSpacing._4)
        .padding(.trailing, TokenSpacing._5)
        .padding(.vertical, TokenSpacing._3)
    }

    private var openButton: some View {
        Button(action: openFile) {
            Text(Strings.Localizable.openButton)
                .font(.subheadline)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                .padding(.horizontal, Constants.openButtonHorizontalPadding)
                .padding(.vertical, Constants.openButtonVerticalPadding)
                .background(TokenColors.Button.secondary.swiftUI)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    /// The task belongs to the view rather than to the view model, which only exposes the async work.
    private func openFile() {
        Task {
            await viewModel.openFile()
        }
    }
}
