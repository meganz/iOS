import Foundation

final class NodeDescriptionTextContentViewModel {
    let textViewEdgeInsets: UIEdgeInsets
    let editingDisabled: Bool

    let descriptionUpdated: (String) -> Void
    let saveDescription: (String) -> Void
    private let maxCharactersAllowed: Int

    init(
        maxCharactersAllowed: Int,
        editingDisabled: Bool,
        textViewEdgeInsets: UIEdgeInsets,
        descriptionUpdated: @escaping (String) -> Void,
        saveDescription: @escaping (String) -> Void
    ) {
        self.maxCharactersAllowed = maxCharactersAllowed
        self.editingDisabled = editingDisabled
        self.textViewEdgeInsets = textViewEdgeInsets
        self.descriptionUpdated = descriptionUpdated
        self.saveDescription = saveDescription
    }

    /// Determines if editing should end based on the given text.
    /// - Parameter text: The text being edited.
    /// - Returns: `true` if the text contains only one character and that character is a newline, indicating that editing should end. Otherwise, returns `false`.
    func shouldEndEditing(for text: String) -> Bool {
        text.count == 1 && text.last?.isNewline == true
    }

    func shouldChangeTextIn(
        in range: NSRange,
        currentText: String,
        replacementText: String
    ) -> Bool {
        let newLength = currentText.count - range.length + replacementText.count
        guard newLength > maxCharactersAllowed else { return true }
        return false
    }

    func truncateAndReplaceText(
        in targetRange: NSRange,
        of currentText: String,
        with newText: String
    ) -> String? {
        guard let stringRange = Range(targetRange, in: currentText) else { return nil }

        let maxReplaceableLength = maxCharactersAllowed - (currentText.count - targetRange.length)
        guard maxReplaceableLength > 0 else { return nil }

        // Ensure that allowedEndIndex does not exceed newText's length
        let endIndex = min(maxReplaceableLength, newText.count)
        let allowedEndIndex = newText.index(newText.startIndex, offsetBy: endIndex)

        let truncatedText = String(newText[..<allowedEndIndex])
        return currentText.replacingCharacters(in: stringRange, with: truncatedText)
    }
}
