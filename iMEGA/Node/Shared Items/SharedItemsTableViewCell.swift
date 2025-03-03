import MEGADesignToken
import MEGAPresentation
import UIKit

@objc protocol SharedItemsTableViewCellDelegate {
    func didTapInfoButton(sender: UIButton)
}

final class SharedItemsTableViewCell: UITableViewCell {

    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var nameLabel: MEGALabel!
    @IBOutlet weak var takeDownView: UIView!
    @IBOutlet weak var takeDownImageView: UIImageView!
    @IBOutlet weak var labelView: UIView!
    @IBOutlet weak var labelImageView: UIImageView!
    @IBOutlet weak var favouriteView: UIView!
    @IBOutlet weak var favouriteImageView: UIImageView!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var permissionsButton: UIButton!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var contactVerifiedImageView: UIImageView!
    
    @IBOutlet weak var descriptionLabel: UILabel!

    @objc var delegate: (any SharedItemsTableViewCellDelegate)?
    
    @objc var nodeHandle: UInt64 = 0
    
    @objc var isTakenDownNode: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateAppearance()
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        infoButton.isHidden = editing
    }
    
    @IBAction func infoButtonTouchUpInside(_ sender: UIButton) {
        delegate?.didTapInfoButton(sender: sender)
    }
    
    // Pragma mark: - Private
    
    private func updateAppearance() {
        nameLabel.tintColor = isTakenDownNode ? TokenColors.Text.error : TokenColors.Text.primary
        infoLabel.textColor = TokenColors.Text.secondary
        backgroundColor = TokenColors.Background.page
        infoButton.tintColor = TokenColors.Icon.secondary
        descriptionLabel.textColor = TokenColors.Text.secondary
        takeDownView.isHidden = !isTakenDownNode
    }

    @objc func setNodeDescription(_ desc: NSAttributedString?) {
        descriptionLabel?.attributedText = desc
        // Note: For some reason app will crash without setting the `descriptionLabel?.textColor` so we need to put it here
        descriptionLabel?.textColor = TokenColors.Text.secondary
    }
    
    @objc func configureNode(name: String, searchText: String?, isTakenDown: Bool) {
        let textColor = isTakenDown ? TokenColors.Text.error : TokenColors.Text.primary
        let takeDownImage: UIImage? = isTakenDown ? UIImage.isTakedown.withTintColorAsOriginal(TokenColors.Support.error) : nil

        nameLabel.attributedText = name.highlightedStringWithKeyword(
            searchText,
            primaryTextColor: textColor,
            highlightedTextColor: TokenColors.Notifications.notificationSuccess
        )
        isTakenDownNode = isTakenDown
        takeDownView.isHidden = !isTakenDown
        takeDownImageView.image = takeDownImage
        // Note: For some reason app will crash without setting the `nameLabel.textColor` so we need to put it here
        nameLabel.textColor = textColor
    }
}
