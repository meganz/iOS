import MEGADesignToken
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

    @objc func setNodeDescription(_ desc: String?) {
        descriptionLabel?.text = desc
    }
    
    @objc func configureNode(_ name: String, isTakenDown: Bool) {
        nameLabel.text = name
        isTakenDownNode = isTakenDown
        takeDownView.isHidden = !isTakenDown

        if isTakenDown {
            takeDownImageView.image = UIImage.isTakedown.withTintColorAsOriginal(TokenColors.Support.error)
            nameLabel.textColor = TokenColors.Text.error
        } else {
            nameLabel.textColor = TokenColors.Text.primary
        }
    }
}
