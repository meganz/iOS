import MEGADesignToken
import MEGAL10n
import SwiftUI

/// The New text file dialog. The user types a name and can choose a rich text file.
public struct NewTextFileDialogView: View {
    @Bindable private var viewModel: NewTextFileDialogViewModel
    private let focusesOnAppear: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// - Parameter focusesOnAppear: Whether the name field takes focus and shows the keyboard. Snapshots pass false.
    public init(viewModel: NewTextFileDialogViewModel, focusesOnAppear: Bool = true) {
        self.viewModel = viewModel
        self.focusesOnAppear = focusesOnAppear
    }

    public var body: some View {
        ZStack {
            TokenColors.Background.blur.swiftUI
                .ignoresSafeArea()
            card
        }
    }

    private var card: some View {
        VStack(spacing: TokenSpacing._3) {
            Text(viewModel.title)
                .font(.headline)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            nameField
            NewTextFileRichTextRow(isChecked: $viewModel.isRichTextChecked)
            buttons
        }
        .padding(TokenSpacing._5)
        .frame(maxWidth: 300)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 34))
        .padding(TokenSpacing._5)
    }

    private var nameField: some View {
        NewTextFileNameField(
            text: viewModel.fileName,
            isInvalid: viewModel.hasInvalidCharacters,
            focusesOnAppear: focusesOnAppear,
            onChange: { viewModel.setFileName($0) },
            onSubmit: { viewModel.didSubmit() }
        )
        .padding(.horizontal, TokenSpacing._5)
        .padding(.vertical, TokenSpacing._4)
        .background(TokenColors.Background.page.swiftUI, in: RoundedRectangle(cornerRadius: TokenRadius.medium))
        .overlay {
            RoundedRectangle(cornerRadius: TokenRadius.medium)
                .stroke(TokenColors.Border.strong.swiftUI, lineWidth: 1)
        }
    }

    private var buttons: some View {
        // Large text does not fit two buttons side by side.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: TokenSpacing._3))
            : AnyLayout(HStackLayout(spacing: TokenSpacing._5))
        return layout {
            Button {
                viewModel.didTapCancel()
            } label: {
                Text(Strings.Localizable.cancel)
                    .font(.headline)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Color(uiColor: .secondarySystemFill), in: Capsule())
            }
            Button {
                viewModel.didTapCreate()
            } label: {
                Text(Strings.Localizable.MarkdownEditor.NewFile.create)
                    .font(.headline)
                    .foregroundStyle(viewModel.isCreateEnabled ? TokenColors.Text.inverseAccent.swiftUI : TokenColors.Text.onColorDisabled.swiftUI)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(viewModel.isCreateEnabled ? TokenColors.Button.primary.swiftUI : TokenColors.Button.disabled.swiftUI, in: Capsule())
            }
            .disabled(!viewModel.isCreateEnabled)
        }
        .buttonStyle(.plain)
    }
}
