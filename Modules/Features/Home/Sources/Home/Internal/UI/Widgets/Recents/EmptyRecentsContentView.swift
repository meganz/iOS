import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

struct EmptyRecentsContentView: View {
    private let viewModel: EmptyRecentsContentViewModel
    let uploadAction: @MainActor () -> Void

    init(
        viewModel: EmptyRecentsContentViewModel = EmptyRecentsContentViewModel(),
        uploadAction: @escaping @MainActor () -> Void
    ) {
        self.viewModel = viewModel
        self.uploadAction = uploadAction
    }

    var body: some View {
        HStack(spacing: TokenSpacing._4) {
            VStack(alignment: .leading, spacing: TokenSpacing._1) {
                Text(Strings.Localizable.Recents.EmptyState.Empty.message)
                    .font(.footnote)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                    .frame(maxWidth: .infinity, alignment: .leading)

                uploadButton
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, TokenSpacing._3)

            MEGAAssets.Image.recentsClock
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
        }
        .padding(.horizontal, TokenSpacing._5)
    }

    private var uploadButton: some View {
        Button {
            viewModel.trackUploadButtonTapped()
            uploadAction()
        } label: {
            Text(Strings.Localizable.upload)
                .font(.callout)
                .fontWeight(.semibold)
                .underline()
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                .frame(height: 32, alignment: .center)
        }
    }
}
