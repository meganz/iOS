import MEGADesignToken
import MEGAL10n
import MEGASwift
import MEGAUIKit

extension MEGANode {

    @objc func attributedName(searchText: String?) -> NSAttributedString {
        name?.highlightedStringWithKeyword(
            searchText,
            primaryTextColor: TokenColors.Text.primary,
            highlightedTextColor: TokenColors.Notifications.notificationSuccess
        ) ?? .init()
    }

    /// Create an NSAttributedString with the name of the node and append isTakedown image
    /// - Returns: The name of the node appending isTakedown image at the end
    @objc func attributedTakenDownName(searchText: String?) -> NSAttributedString {
        let highlightedName = name?.highlightedStringWithKeyword(searchText, primaryTextColor: TokenColors.Text.error, highlightedTextColor: TokenColors.Notifications.notificationSuccess) ?? .init()
        let name = NSMutableAttributedString(attributedString: highlightedName)

        let takedownImageAttachment = NSTextAttachment()
        let takeDownImage = UIImage(named: "isTakedown")
        
        takedownImageAttachment.image = takeDownImage?.withTintColorAsOriginal(.mnz_takenDownNodeIconColor())
        let takedownImageString = NSAttributedString(attachment: takedownImageAttachment)
        
        name.append(takedownImageString)
        
        return name
    }

    @objc func attributedTakenDownName() -> NSAttributedString {
        attributedTakenDownName(searchText: nil)
    }

    @objc func attributedDescription(searchText: String?) -> NSAttributedString {
        description?.highlightedStringWithKeyword(
            searchText,
            primaryTextColor: TokenColors.Text.secondary,
            highlightedTextColor: TokenColors.Notifications.notificationSuccess
        ) ?? .init()
    }

    @objc func fileFolderRenameAlertTitle(invalidChars containsInvalidChars: Bool) -> String {
        guard containsInvalidChars else {
            return Strings.Localizable.rename
        }
        return Strings.Localizable.General.Error.charactersNotAllowed(String.Constants.invalidFileFolderNameCharactersToDisplay)
    }
    
    @objc func alertMessage(forRemoved nodeType: MEGANodeType) -> String {
        Strings.Localizable.SharedItems.Rubbish.Warning.message(
            (nodeType == .folder) ? Strings.Localizable.SharedItems.Rubbish.Warning.folderCount(1) : Strings.Localizable.SharedItems.Rubbish.Warning.fileCount(1)
        )
    }
}
