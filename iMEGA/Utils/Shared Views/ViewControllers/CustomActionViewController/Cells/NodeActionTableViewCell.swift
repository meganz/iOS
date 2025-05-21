import MEGAAssets
import MEGADesignToken

final class NodeActionTableViewCell: ActionSheetCell {
    func configureCell(action: NodeAction) {
        super.configureCell(action: action)
        
        guard let title = action.title,
              action.showProTag else { return }
        textLabel?.attributedText = makeProTagAttributedString(title: title,
                                                               style: action.style)
    }
    
    private func makeProTagAttributedString(title: String,
                                            style: UIAlertAction.Style) -> NSAttributedString {
        let titleAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: textColour(style: style)]
        let fullString = NSMutableAttributedString(string: title,
                                                   attributes: titleAttributes)
        
        let spaceAttachment = NSTextAttachment()
        spaceAttachment.bounds = CGRect(x: 0, y: 0, width: 8.0, height: 0)
        
        let proLabelImage = NSTextAttachment(image: MEGAAssets.UIImage.proLabel)
        proLabelImage.bounds = CGRect(x: 0, y: 0, width: 23.5, height: 13)
        
        fullString.append(NSAttributedString(attachment: spaceAttachment))
        fullString.append(NSAttributedString(attachment: proLabelImage))
        
        return fullString
    }
    
    private func textColour(style: UIAlertAction.Style) -> UIColor {
        switch style {
        case .cancel, .destructive:
            return TokenColors.Support.error
        default:
            return TokenColors.Text.primary
        }
    }
}
