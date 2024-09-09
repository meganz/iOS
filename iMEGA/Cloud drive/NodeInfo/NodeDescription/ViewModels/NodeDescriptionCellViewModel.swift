import Foundation
import MEGADesignToken
import MEGAL10n
import MEGASwift

final class NodeDescriptionCellViewModel {
    let textViewEdgeInsets: UIEdgeInsets
    let editingDisabled: () -> Bool
    let descriptionUpdated: (String) -> Void
    let saveDescription: (String) -> Void
    let isTextViewFocused: (Bool) -> Void
    private let maxCharactersAllowed: Int
    private let hasReadOnlyAccess: () -> Bool
    private let descriptionProvider: () -> NodeDescriptionCellControllerModel.Description?
    
    var onUpdate: (() -> Void)?

    init(
        maxCharactersAllowed: Int,
        editingDisabled: @escaping () -> Bool,
        textViewEdgeInsets: UIEdgeInsets,
        descriptionProvider: @escaping () -> NodeDescriptionCellControllerModel.Description?,
        hasReadOnlyAccess: @escaping () -> Bool,
        descriptionUpdated: @escaping (String) -> Void,
        saveDescription: @escaping (String) -> Void,
        isTextViewFocused: @escaping (Bool) -> Void
    ) {
        self.maxCharactersAllowed = maxCharactersAllowed
        self.editingDisabled = editingDisabled
        self.textViewEdgeInsets = textViewEdgeInsets
        self.descriptionProvider = descriptionProvider
        self.hasReadOnlyAccess = hasReadOnlyAccess
        self.descriptionUpdated = descriptionUpdated
        self.saveDescription = saveDescription
        self.isTextViewFocused = isTextViewFocused
    }
    
    /// The text to be displayed on the text view
    /// - Parameter isEditing: Indicates whether the text view is being edited or not
    /// - Returns: Proper text to display on the view
    
    func displayText(isEditing: Bool) -> String? {
        guard let description = descriptionProvider() else { return nil }
        if description.isPlaceholder {
            // Upon node update, if the updated desc is empty and the description is being edited in the textview,
            // we display "" instead of the placeholder.
            if isEditing {
                return ""
            } else {
                return placeholderText
            }
        } else {
            return description.content
        }
    }
    
    var placeholderText: String {
        hasReadOnlyAccess() ? Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.EmptyText.readOnly
        : Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.EmptyText.readWrite
    }
    
    var isPlaceholder: Bool {
        descriptionProvider()?.isPlaceholder == true
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
        let newLength = currentText.utf16.count - range.length + replacementText.utf16.count
        guard newLength > maxCharactersAllowed else { return true }
        return false
    }

    func truncateAndReplaceText(
        in targetRange: NSRange,
        of currentText: String,
        with newText: String
    ) -> String? {
        guard let stringRange = Range(targetRange, in: currentText) else { return nil }

        let maxReplaceableLength = maxCharactersAllowed - (currentText.utf16.count - targetRange.length)
        guard maxReplaceableLength > 0,
              let truncatedText = newText.utf16ValidatedTruncation(to: maxReplaceableLength) else {
            return nil
        }

        return currentText.replacingCharacters(in: stringRange, with: truncatedText)
    }
}
