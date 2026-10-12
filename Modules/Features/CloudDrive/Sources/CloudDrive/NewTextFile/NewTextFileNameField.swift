import MEGADesignToken
import MEGAL10n
import SwiftUI
import UIKit

/// A UIKit field, because SwiftUI cannot place the caret before iOS 18.
/// The caret starts at the beginning of the name, so the user can type the base name before the extension.
struct NewTextFileNameField: UIViewRepresentable {
    let text: String
    let isInvalid: Bool
    let focusesOnAppear: Bool
    let onChange: (String) -> Void
    let onSubmit: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onChange: onChange, onSubmit: onSubmit)
    }

    func makeUIView(context: Context) -> FocusingTextField {
        let textField = FocusingTextField()
        textField.focusesOnAppear = focusesOnAppear
        textField.delegate = context.coordinator
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textDidChange(_:)), for: .editingChanged)
        textField.placeholder = Strings.Localizable.fileName
        textField.font = UIFont.preferredFont(forTextStyle: .callout)
        textField.adjustsFontForContentSizeCategory = true
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.returnKeyType = .done
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return textField
    }

    func updateUIView(_ textField: FocusingTextField, context: Context) {
        context.coordinator.onChange = onChange
        context.coordinator.onSubmit = onSubmit
        if textField.text != text {
            // Setting the text moves the caret to the end. The box changes only the extension, so keep the caret.
            let caretOffset = textField.selectedTextRange.map { textField.offset(from: textField.beginningOfDocument, to: $0.start) }
            textField.text = text
            if let caretOffset,
               let caret = textField.position(from: textField.beginningOfDocument, offset: min(caretOffset, text.utf16.count)) {
                textField.selectedTextRange = textField.textRange(from: caret, to: caret)
            }
        }
        textField.textColor = isInvalid ? TokenColors.Text.error : TokenColors.Text.primary
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: FocusingTextField, context: Context) -> CGSize? {
        let height = uiView.intrinsicContentSize.height
        return CGSize(width: proposal.width ?? uiView.intrinsicContentSize.width, height: height)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, UITextFieldDelegate {
        var onChange: (String) -> Void
        var onSubmit: () -> Void

        init(onChange: @escaping (String) -> Void, onSubmit: @escaping () -> Void) {
            self.onChange = onChange
            self.onSubmit = onSubmit
        }

        @objc func textDidChange(_ textField: UITextField) {
            onChange(textField.text ?? "")
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.beginningOfDocument)
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            onSubmit()
            return false
        }
    }
}

/// A text field that takes focus when it joins a window.
final class FocusingTextField: UITextField {
    var focusesOnAppear = false

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil, focusesOnAppear {
            becomeFirstResponder()
        }
    }
}
