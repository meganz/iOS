import MEGADesignToken
import MEGAL10n
import SwiftUI
import UIKit

struct PDFViewerPasswordView: View {
    @Binding var password: String
    let showInvalidPasswordError: Bool
    let passwordRejectionCount: Int
    let isSubmissionEnabled: Bool
    let isSubmitting: Bool
    let onOpen: () -> Void
    let onCancel: () -> Void

    @ScaledMetric(relativeTo: .body) private var fieldHeight = 52
    @ScaledMetric(relativeTo: .body) private var buttonHeight = 48
    @FocusState private var isPasswordFocused: Bool

    var body: some View {
        ZStack {
            TokenColors.Background.blur.swiftUI
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: TokenSpacing._3 + TokenSpacing._1) {
                    titleSubtitleAndError
                    passwordInput
                    actionButtons
                }
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                .multilineTextAlignment(.leading)
                .padding(TokenSpacing._4 + TokenSpacing._1)
                .frame(maxWidth: 300)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 34))
                .shadow(color: .black.opacity(0.08), radius: 20, y: 5)
                .padding(TokenSpacing._5)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            .defaultScrollAnchor(.center)
        }
        .accessibilityAddTraits(.isModal)
        .task { isPasswordFocused = true }
        .onChange(of: passwordRejectionCount) { _, _ in
            isPasswordFocused = true
            UIAccessibility.post(
                notification: .announcement,
                argument: Strings.Localizable.PdfPreview.Password.invalid
            )
        }
        .onChange(of: isSubmissionEnabled) { _, isEnabled in
            if isEnabled { isPasswordFocused = true }
        }
    }

    private var titleSubtitleAndError: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._3 + TokenSpacing._1) {
            Text(Strings.Localizable.PdfPreview.Password.title)
                .font(.body.weight(.semibold))
                .accessibilityAddTraits(.isHeader)
            Text(Strings.Localizable.PdfPreview.Password.message)
                .font(.body)
            Text(Strings.Localizable.PdfPreview.Password.invalid)
                .font(.caption2)
                .foregroundStyle(TokenColors.Text.brand.swiftUI)
                .opacity(showInvalidPasswordError ? 1 : 0)
                .accessibilityHidden(!showInvalidPasswordError)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, TokenSpacing._3)
        .padding(.top, TokenSpacing._3)
        .padding(.bottom, 1)
    }

    private var passwordInput: some View {
        HStack(spacing: TokenSpacing._2) {
            SecureField("", text: $password)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.go)
                .focused($isPasswordFocused)
                .onSubmit { if isSubmissionEnabled { onOpen() } }
                .accessibilityLabel(Strings.Localizable.passwordPlaceholder)
                .accessibilityIdentifier("pdfPasswordField")
            if !password.isEmpty {
                Button {
                    password = ""
                    isPasswordFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(TokenColors.Text.placeholder.swiftUI)
                }
                .accessibilityLabel(Strings.Localizable.clear)
            }
        }
        .font(.body)
        .padding(.horizontal, TokenSpacing._5)
        .frame(minHeight: fieldHeight)
        .background(Color(.secondarySystemFill), in: Capsule())
        .disabled(isSubmitting)
        .padding(.bottom, TokenSpacing._6 - 1)
    }

    private var actionButtons: some View {
        HStack(spacing: TokenSpacing._5) {
            Button(action: onCancel) {
                Text(Strings.Localizable.cancel)
                    .frame(maxWidth: .infinity, minHeight: buttonHeight)
                    .background(Color(.secondarySystemFill), in: Capsule())
            }
            .foregroundStyle(isSubmitting ? TokenColors.Text.disabled.swiftUI : TokenColors.Text.primary.swiftUI)
            .disabled(isSubmitting)
            Button(action: onOpen) {
                ZStack {
                    Text(Strings.Localizable.openButton)
                        .opacity(isSubmitting ? 0 : 1)
                    if isSubmitting { ProgressView().tint(TokenColors.Text.inverseAccent.swiftUI) }
                }
                .frame(maxWidth: .infinity, minHeight: buttonHeight)
                .foregroundStyle(isSubmissionEnabled
                    ? TokenColors.Text.inverseAccent.swiftUI
                    : TokenColors.Text.disabled.swiftUI)
                .background(isSubmissionEnabled
                    ? TokenColors.Button.primary.swiftUI
                    : TokenColors.Button.disabled.swiftUI, in: Capsule())
            }
            .disabled(!isSubmissionEnabled)
            .accessibilityLabel(Strings.Localizable.openButton)
            .accessibilityIdentifier("pdfPasswordOpen")
        }
        .font(.body.weight(.medium))
        .buttonStyle(.plain)
    }
}
