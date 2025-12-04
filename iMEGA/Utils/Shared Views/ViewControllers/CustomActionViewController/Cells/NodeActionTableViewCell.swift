import MEGAAppPresentation
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

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureForRevampUIIfNeeded()
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureForRevampUIIfNeeded() {
        if DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .cloudDriveRevamp) {
            guard let imgView = imageView, let label = self.textLabel else { return }

            imgView.translatesAutoresizingMaskIntoConstraints = false
            label.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                imgView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
                imgView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                imgView.widthAnchor.constraint(equalToConstant: TokenSpacing._7),
                imgView.heightAnchor.constraint(equalToConstant: TokenSpacing._7),
                label.leadingAnchor.constraint(equalTo: imgView.trailingAnchor, constant: TokenSpacing._4),
                imgView.centerYAnchor.constraint(equalTo: label.centerYAnchor),
                label.topAnchor.constraint(equalTo: contentView.topAnchor),
                label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
            imgView.contentMode = .scaleAspectFit
        }
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
