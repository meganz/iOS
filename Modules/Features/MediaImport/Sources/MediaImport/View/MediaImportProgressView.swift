import MEGADesignToken
import MEGAL10n
import SwiftUI

public struct MediaImportProgressView: View {
    @StateObject private var viewModel: MediaImportProgressViewModel

    public init(viewModel: @autoclosure @escaping () -> MediaImportProgressViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    public var body: some View {
        VStack(spacing: TokenSpacing._5) {
            Text(Strings.Localizable.MediaImport.Preparing.title)
                .font(.headline)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)

            Text(Strings.Localizable.MediaImport.Preparing.progress(viewModel.completedCount).replacing("[A]", with: String(format: "%d", viewModel.totalCount)))
                .font(.subheadline)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)

            ProgressView(value: viewModel.progress)
                .tint(TokenColors.Button.primary.swiftUI)
        }
        .padding(TokenSpacing._7)
        .frame(width: 280)
        .background(TokenColors.Background.surface1.swiftUI)
        .clipShape(RoundedRectangle(cornerRadius: TokenRadius.large))
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TokenColors.Background.blur.swiftUI)
    }
}
